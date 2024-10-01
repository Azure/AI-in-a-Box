import time

def keep_alive():
    while True:
        print("Keep Alive")
        time.sleep(60)  # Espera 60 segundos antes de imprimir de nuevo

if __name__ == "__main__":
    keep_alive()
