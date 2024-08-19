import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin, urlparse
import os

def is_valid_url(url):
    parsed = urlparse(url)
    return bool(parsed.netloc) and bool(parsed.scheme)

def get_all_links(url):
    try:
        # Fazendo a requisição GET para a URL
        response = requests.get(url)
        if response.status_code != 200:
            print(f"Falha ao acessar {url}. Código de status: {response.status_code}")
            return []

        # Parsing do conteúdo HTML
        soup = BeautifulSoup(response.text, "html.parser")
        links = set()

        # Encontrando todos os links na página
        for a_tag in soup.find_all("a", href=True):
            href = a_tag['href']
            full_url = urljoin(url, href)

            # Verifica se o link é válido e se pertence ao mesmo domínio
            if is_valid_url(full_url) and urlparse(full_url).netloc == urlparse(url).netloc:
                links.add(full_url)

        return links

    except Exception as e:
        print(f"Ocorreu um erro ao processar a URL: {e}")
        return []

def save_html(url, folder_name):
    try:
        response = requests.get(url)
        if response.status_code == 200:
            # Criando um nome de arquivo a partir da URL
            filename = os.path.join(folder_name, urlparse(url).path.replace("/", "_").strip("_") + ".html")
            if not filename.endswith(".html"):
                filename += "index.html"

            with open(filename, "w", encoding="utf-8") as file:
                file.write(response.text)
            print(f"HTML salvo em: {filename}")
        else:
            print(f"Não foi possível acessar {url}. Código de status: {response.status_code}")
    except Exception as e:
        print(f"Erro ao salvar {url}: {e}")

def main():
    url_principal = input("Digite a URL principal (ex: https://www.exemplo.com): ").strip()

    if not is_valid_url(url_principal):
        print("URL inválida. Por favor, tente novamente.")
        return

    folder_name = "html_paginas"
    os.makedirs(folder_name, exist_ok=True)

    print("Buscando páginas relacionadas...")
    links = get_all_links(url_principal)

    if not links:
        print("Nenhuma página encontrada.")
        return

    print(f"{len(links)} páginas encontradas. Salvando HTMLs...")

    # Salvando o HTML da página principal também
    save_html(url_principal, folder_name)

    for link in links:
        save_html(link, folder_name)

    print("Processo concluído!")

if __name__ == "__main__":
    main()
