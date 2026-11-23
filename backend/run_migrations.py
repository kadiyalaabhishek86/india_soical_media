import psycopg2
import glob
import os

DB_URL = "postgresql://postgres.xhhmznptzuovqbfnfnuk:hbqJ6PTWFT8pV8D2@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def run_migrations():
    print(f"Connecting to Supabase PostgreSQL at aws-1-ap-south-1.pooler.supabase.com...")
    conn = psycopg2.connect(DB_URL)
    conn.autocommit = True
    cur = conn.cursor()

    migration_files = sorted(glob.glob("supabase/migrations/*.sql"))
    print(f"Found {len(migration_files)} migration files.")

    for mf in migration_files:
        print(f"Applying: {mf} ...")
        with open(mf, "r", encoding="utf-8") as f:
            sql = f.read()
        try:
            cur.execute(sql)
            print(f"  [OK] {os.path.basename(mf)}")
        except Exception as e:
            print(f"  [ERROR] {os.path.basename(mf)}: {e}")

    seed_file = "supabase/seed_demo.sql"
    if os.path.exists(seed_file):
        print(f"Applying Seed: {seed_file} ...")
        with open(seed_file, "r", encoding="utf-8") as f:
            sql = f.read()
        try:
            cur.execute(sql)
            print("  [OK] Seed applied")
        except Exception as e:
            print(f"  [ERROR] Seed: {e}")

    cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;")
    tables = cur.fetchall()
    print("\nVerified Tables in Supabase public schema:")
    for t in tables:
        print(f" - {t[0]}")

    conn.close()
    print("\nSupabase Database Migration & Seeding Complete!")

if __name__ == "__main__":
    run_migrations()
