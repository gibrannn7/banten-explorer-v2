from fastapi import FastAPI, UploadFile, File, Form
from pydantic import BaseModel
import faiss
import numpy as np
import json
import tempfile
import shutil
import os
from sentence_transformers import SentenceTransformer
from groq import Groq
from dotenv import load_dotenv

load_dotenv()
GROQ_API_KEY = os.getenv("GROQ_API_KEY")
GROQ_WHISPER_MODEL = os.getenv("GROQ_WHISPER_MODEL", "whisper-large-v3")

app = FastAPI()
client = Groq()
model = SentenceTransformer('all-MiniLM-L6-v2')

index = faiss.read_index("banten_wisata.faiss")
with open("metadata.json", "r", encoding='utf-8') as f:
    metadatas = json.load(f)
with open("documents.json", "r", encoding='utf-8') as f:
    documents = json.load(f)

class ChatRequest(BaseModel):
    query: str
    language: str = "id_ID" 

# MAPPER 7 BAHASA
def get_language_context(locale_code: str):
    mapping = {
        'id_ID': ('id', 'Indonesian (Bahasa Indonesia)'),
        'en_US': ('en', 'English'),
        'ja_JP': ('ja', 'Japanese (日本語)'),
        'zh_CN': ('zh', 'Mandarin (中文)'),
        'ar_SA': ('ar', 'Arabic (العربية)'),
        'fr_FR': ('fr', 'French (Français)'),
        'de_DE': ('de', 'German (Deutsch)')
    }
    return mapping.get(locale_code, ('id', 'Indonesian (Bahasa Indonesia)'))

# ENHANCEMENT: PROMPT ABSOLUT (TANGAN BESI)
# AI Dilarang auto-detect, WAJIB menggunakan target_lang dari Frontend!
def get_dynamic_prompt(context_string: str, user_query: str, target_lang: str):
    return f"""
    You are 'Banten Explorer', an AI tourism assistant for Banten, Indonesia.
    You must answer user questions accurately based ONLY on the Data Context provided below.
    
    CRITICAL INSTRUCTION FOR LANGUAGE (ABSOLUTE RULE):
    YOU ARE STRICTLY REQUIRED TO RESPOND ENTIRELY IN THE FOLLOWING LANGUAGE: {target_lang}.
    Do NOT reply in Indonesian unless the requested language is explicitly Indonesian.
    You MUST translate all facts, facilities, and explanations from the Data Context into {target_lang} naturally.
    
    Data Context:
    {context_string}
    
    User Query: {user_query}
    
    Writing Rules for "pesan" (message key):
    1. Respond naturally, politely, and informatively as a tour guide in {target_lang}.
    2. PENTING: If you list facilities, activities, routes, menus, or prices, YOU MUST format them as bullet points using '-' and a newline '\\n'.
    3. If you describe places or history, use normal paragraphs.
    4. NEVER include image URLs directly inside the "pesan" text.
    
    Image Display Rules ("gambar_urls" key):
    1. Analyze: Did the user ask for a picture/photo explicitly?
    2. If YES: Find all image URLs in the Context. IMPORTANT: URLs in the context are often separated by the '|' symbol. YOU MUST split them and put each link as a separate item in the array.
    3. If NO: return an empty array [].
    
    JSON Format Strict Rule:
    Your output MUST be a valid JSON object without markdown blocks.
    1. "pesan": Your answer translated perfectly into {target_lang}.
    2. "tampilkan_map": true ONLY if asked for routes, directions, or locations, else false.
    3. "keyword_lokasi": Specific location name if map is true, else null.
    4. "gambar_urls": Array of image URLs based on the rule above.
    """

@app.post("/chat")
async def chat_with_bot(request: ChatRequest):
    user_query = request.query
    iso_code, lang_name = get_language_context(request.language)
    
    query_vector = model.encode([user_query])
    D, I = index.search(np.array(query_vector), k=6) 
    
    context_texts = []
    for idx in I[0]:
        context_texts.append(documents[idx])
        
    context_string = "\n".join(context_texts)
    
    # Paksa pakai bahasa dari Frontend
    prompt = get_dynamic_prompt(context_string, user_query, lang_name)
    
    chat_completion = client.chat.completions.create(
        messages=[{"role": "user", "content": prompt}],
        model="llama-3.3-70b-versatile",
        response_format={"type": "json_object"}, 
        temperature=0.3 
    )
    
    response_data = json.loads(chat_completion.choices[0].message.content)
    return response_data

@app.post("/chat/audio")
async def chat_with_audio(file: UploadFile = File(...), language: str = Form("id_ID")):
    iso_code, lang_name = get_language_context(language)

    with tempfile.NamedTemporaryFile(delete=False, suffix=".m4a") as temp_audio:
        shutil.copyfileobj(file.file, temp_audio)
        temp_audio_path = temp_audio.name

    try:
        # Transcribe: Whisper DIKUNCI MATI ke bahasa yang dipilih di Frontend
        with open(temp_audio_path, "rb") as audio_file:
            transcription = client.audio.transcriptions.create(
                file=(os.path.basename(temp_audio_path), audio_file.read()),
                model=GROQ_WHISPER_MODEL,
                response_format="json",
                language=iso_code, # KUNCIAN BAHASA DIAKTIFKAN KEMBALI
                prompt=f"Tourism in Banten, wisata Banten, in {lang_name}" 
            )
        
        user_query = transcription.text
        
        if not user_query.strip():
            return {
                "user_text": "",
                "bot_response": {
                    "pesan": f"Audio could not be recognized in {lang_name} / Suara tidak terdengar.",
                    "tampilkan_map": False,
                    "keyword_lokasi": None,
                    "gambar_urls": []
                }
            }

        query_vector = model.encode([user_query])
        D, I = index.search(np.array(query_vector), k=6) 
        
        context_texts = []
        for idx in I[0]:
            context_texts.append(documents[idx])
            
        context_string = "\n".join(context_texts)
        
        prompt = get_dynamic_prompt(context_string, user_query, lang_name)
        
        chat_completion = client.chat.completions.create(
            messages=[{"role": "user", "content": prompt}],
            model="llama-3.3-70b-versatile",
            response_format={"type": "json_object"}, 
            temperature=0.3 
        )
        
        response_data = json.loads(chat_completion.choices[0].message.content)
        
        return {
            "user_text": user_query,
            "bot_response": response_data
        }
    finally:
        if os.path.exists(temp_audio_path):
            os.remove(temp_audio_path)