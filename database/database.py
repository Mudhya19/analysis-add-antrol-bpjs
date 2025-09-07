"""
Database Module untuk Koneksi dan Query BPJS
"""

import MySQLdb
import pandas as pd
import streamlit as st
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
import os


class DatabaseManager:
    """Kelas untuk mengelola koneksi dan operasi database"""
    
    def __init__(self):
        """Inisialisasi konfigurasi database"""
        self.config = {
            'host': os.getenv("DB_HOST", "192.168.11.5"),
            'user': os.getenv("DB_USER", "rsds_db"),
            'passwd': os.getenv("DB_PASS", "rsdsD4t4b4s3"),
            'db': os.getenv("DB_NAME", "rsds_db"),
            'port': int(os.getenv("DB_PORT", 3306))
        }
    
    def get_connection(self) -> Optional[MySQLdb.Connection]:
        """Membuat dan mengembalikan koneksi MySQL database"""
        try:
            connection = MySQLdb.connect(**self.config)
            return connection
        except MySQLdb.Error as err:
            st.error(f"Error Koneksi Database: {err}")
            return None
    
    def execute_query(self, query: str, params: tuple = None) -> Optional[pd.DataFrame]:
        """Eksekusi query SQL dan mengembalikan hasil sebagai DataFrame"""
        connection = self.get_connection()
        if connection is None:
            return None
        
        try:
            cursor = connection.cursor(MySQLdb.cursors.DictCursor)
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)
            
            data = cursor.fetchall()
            cursor.close()
            connection.close()
            
            return pd.DataFrame(data) if data else pd.DataFrame()
            
        except MySQLdb.Error as err:
            st.error(f"Error Query Database: {err}")
            if connection:
                connection.close()
            return None


class BPJSQueryManager(DatabaseManager):
    """Kelas khusus untuk query BPJS yang mewarisi DatabaseManager"""
    
    def format_jam_reg(self, data: pd.DataFrame) -> pd.DataFrame:
        """Format kolom jam_reg menjadi format HH:MM:SS"""
        if 'jam_reg' in data.columns:
            def format_time(value):
                if isinstance(value, str):
                    try:
                        if len(value) <= 5:
                            return datetime.strptime(value, '%H:%M').strftime('%H:%M:%S')
                        elif len(value) == 8:
                            return value
                    except ValueError:
                        return value
                elif isinstance(value, timedelta):
                    total_seconds = int(value.total_seconds())
                    hours = total_seconds // 3600
                    minutes = (total_seconds % 3600) // 60
                    seconds = total_seconds % 60
                    return f"{hours:02}:{minutes:02}:{seconds:02}"
                return value
            
            data['jam_reg'] = data['jam_reg'].apply(format_time)
        return data
    
    @st.cache_data(show_spinner=True)
    def load_patient_data(_self, start_date: str, end_date: str) -> Optional[pd.DataFrame]:
        """Memuat data pasien BPJS dari database"""
        query = """
        SELECT
            rp.no_rawat,
            rp.tgl_registrasi,
            rp.jam_reg,
            rp.kd_dokter,
            d.nm_dokter,
            rp.no_rkm_medis,
            pas.nm_pasien,
            rp.kd_poli,
            p.nm_poli,
            rp.status_lanjut,
            rp.kd_pj,
            pj.png_jawab,
            mar.tanggal_periksa,
            mar.nomor_kartu,
            mar.nomor_referensi,
            mar.kodebooking,
            mar.jenis_kunjungan,
            mar.status_kirim,
            mar.keterangan,
            bs.USER 
        FROM
            reg_periksa rp
            JOIN mlite_antrian_referensi mar ON rp.no_rkm_medis = mar.no_rkm_medis
            JOIN poliklinik p ON rp.kd_poli = p.kd_poli
            JOIN dokter d ON rp.kd_dokter = d.kd_dokter
            JOIN penjab pj ON rp.kd_pj = pj.kd_pj
            JOIN pasien pas ON rp.no_rkm_medis = pas.no_rkm_medis
            JOIN bridging_sep bs ON rp.no_rawat = bs.no_rawat 
        WHERE
            rp.tgl_registrasi BETWEEN %s AND %s
            AND mar.tanggal_periksa BETWEEN %s AND %s
            AND rp.kd_poli NOT IN ('IGDK', 'HDL', 'BBL', 'IRM', '006', 'U0016')
            AND rp.status_lanjut NOT IN ('Ranap')
        ORDER BY
            rp.no_rawat;
        """
        
        params = (start_date, end_date, start_date, end_date)
        df = _self.execute_query(query, params)
        
        if df is not None and not df.empty:
            return _self.format_jam_reg(df)
        return df
    
    @st.cache_data(show_spinner=True)
    def load_service_logs(_self, start_date: str, end_date: str) -> Optional[pd.DataFrame]:
        """Memuat data service logs dari database"""
        query = """
        SELECT 
            *
        FROM 
            mlite_query_logs 
        WHERE 
            DATE(created_at) BETWEEN %s AND %s
        ORDER BY 
            created_at DESC;
        """
        
        params = (start_date, end_date)
        return _self.execute_query(query, params)
    
    # def get_patient_statistics(self, start_date: str, end_date: str) -> Dict[str, Any]:
    #     """Mendapatkan statistik pasien dalam rentang tanggal tertentu"""
    #     query = """
    #     SELECT 
    #         COUNT(*) as total_kunjungan,
    #         COUNT(DISTINCT rp.no_rkm_medis) as total_pasien_unik,
    #         COUNT(DISTINCT rp.kd_poli) as total_poliklinik,
    #         COUNT(DISTINCT rp.kd_dokter) as total_dokter
    #     FROM reg_periksa rp
    #     WHERE rp.tgl_registrasi BETWEEN %s AND %s
    #     """
        
    #     params = (start_date, end_date)
    #     result = self.execute_query(query, params)
        
    #     if result is not None and not result.empty:
    #         return result.iloc[0].to_dict()
    #     return {}
    
    # def get_top_poliklinik(self, start_date: str, end_date: str, limit: int = 10) -> Optional[pd.DataFrame]:
    #     """Mendapatkan top poliklinik berdasarkan jumlah kunjungan"""
    #     query = """
    #     SELECT 
    #         p.nm_poli,
    #         COUNT(*) as jumlah_kunjungan
    #     FROM reg_periksa rp
    #     JOIN poliklinik p ON rp.kd_poli = p.kd_poli
    #     WHERE rp.tgl_registrasi BETWEEN %s AND %s
    #     GROUP BY rp.kd_poli, p.nm_poli
    #     ORDER BY jumlah_kunjungan DESC
    #     LIMIT %s
    #     """
        
    #     params = (start_date, end_date, limit)
    #     return self.execute_query(query, params)
    
    # def get_hourly_distribution(self, start_date: str, end_date: str) -> Optional[pd.DataFrame]:
    #     """Mendapatkan distribusi kunjungan per jam"""
    #     query = """
    #     SELECT 
    #         HOUR(rp.jam_reg) as jam,
    #         COUNT(*) as jumlah_kunjungan
    #     FROM reg_periksa rp
    #     WHERE rp.tgl_registrasi BETWEEN %s AND %s
    #     GROUP BY HOUR(rp.jam_reg)
    #     ORDER BY jam
    #     """
        
    #     params = (start_date, end_date)
    #     return self.execute_query(query, params)