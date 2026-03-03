from fastapi import FastAPI
from pydantic import BaseModel
import faiss
import numpy as np
import json
import os
from sentence_transformers import SentenceTransformer
from groq import Groq

GROQ_API_KEY = os.getenv("GROQ_API_KEY")
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

@app.post("/chat")
async def chat_with_bot(request: ChatRequest):
    user_query = request.query
    
    query_vector = model.encode([user_query])
    D, I = index.search(np.array(query_vector), k=6) 
    
    context_texts = []
    for idx in I[0]:
        context_texts.append(documents[idx])
        
    context_string = "\n".join(context_texts)
    
    prompt = f"""
    Kamu adalah 'Banten Explorer', asisten AI pariwisata Banten yang cerdas, ramah, dan natural.
    Tugas utamamu adalah menjawab pertanyaan user SECARA DETAIL dan AKURAT HANYA berdasarkan Konteks Data di bawah ini. JANGAN mengarang informasi.
    
    Konteks Data:
    {context_string}
    
    Pertanyaan User: {user_query}
    
    Aturan Penulisan untuk "pesan":
    1. Gunakan gaya bahasa yang ramah dan informatif layaknya pemandu wisata.
    2. PENTING: Jika menyebutkan daftar (seperti fasilitas, aktivitas, rute, menu, harga), WAJIB JADIKAN SEBAGAI LIST (gunakan bullet points dengan tanda strip '-' dan baris baru '\\n') agar rapi.
    3. Jika menjelaskan deskripsi tempat atau sejarah, gunakan paragraf biasa yang mengalir natural.
    4. JANGAN PERNAH memasukkan link/URL gambar ke dalam teks "pesan".
    
    Aturan Tampilan Gambar ("gambar_urls"):
    1. Analisis Pertanyaan User: Apakah user secara eksplisit meminta gambar/foto/visual? (Contoh kata kunci: "ada fotonya", "lihat gambarnya", "kirim foto", "seperti apa bentuknya", "referensi", dll).
    2. Jika YA (diminta): Cari semua URL gambar di Konteks. PENTING: URL di konteks sering dipisahkan oleh tanda '|'. Kamu WAJIB memecahnya dan memasukkan setiap link tersebut menjadi item terpisah di dalam array.
    3. Jika TIDAK (tidak diminta): KOSONGKAN array menjadi [].
    
    Aturan Format JSON Murni:
    1. "pesan": Jawaban lengkap sesuai aturan penulisan.
    2. "tampilkan_map": true (HANYA jika ditanya rute, arah, atau dimana letaknya), selain itu false.
    3. "keyword_lokasi": Nama lokasi spesifik jika map true, jika false isi null.
    4. "gambar_urls": Array/List sesuai "Aturan Tampilan Gambar" di atas.
    
    Format balasan (Wajib murni JSON valid, jadikan ini patokan pemisahan gambar_urls jika diminta foto):
    {{
       "pesan": "Tentu! Di Tanjung Lesung Beach Hotel terdapat banyak fasilitas, antara lain:\\n- Kolam renang outdoor\\n- Akses pantai pribadi\\n- Area bermain anak",
       "tampilkan_map": false,
       "keyword_lokasi": null,
       "gambar_urls": ["https://contoh.com/gambar1.jpg", "https://contoh.com/gambar2.jpg"]
    }}
    """
    
    chat_completion = client.chat.completions.create(
        messages=[{"role": "user", "content": prompt}],
        model="llama-3.3-70b-versatile",
        response_format={"type": "json_object"}, 
        temperature=0.3 
    )
    
    response_data = json.loads(chat_completion.choices[0].message.content)
    return response_data