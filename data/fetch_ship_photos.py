#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Télécharge les photos officielles (domaine public, Wikimedia Commons) des
navires de l'ordre de bataille vers web/public/ships/<ship_id>.jpg.

Idempotent : ne re-télécharge pas un fichier déjà présent (sauf --force).
Les navires sans photo trouvée restent sans fichier ; l'UI affiche alors une
silhouette par type. Usage: python3 fetch_ship_photos.py [--force]"""
import urllib.request, urllib.parse, json, os, sys, time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT  = os.path.join(ROOT, 'web', 'public', 'ships')
UA   = 'midway-recon/1.0 (https://github.com/; thierry.hessel@gmail.com)'
FORCE = '--force' in sys.argv

# ship_id -> article Wikipedia (en) servant de source à la photo de tête.
ARTICLES = {
    # --- IJN ---
    'SH-AKAGI':   'Japanese aircraft carrier Akagi',
    'SH-HIRYU':   'Japanese aircraft carrier Hiryū',
    'SH-KAGA':    'Japanese aircraft carrier Kaga',
    'SH-SORYU':   'Japanese aircraft carrier Sōryū',
    'SH-HOSHO':   'Japanese aircraft carrier Hōshō',
    'SH-HARUNA':  'Japanese battleship Haruna',
    'SH-KIRISHIMA': 'Japanese battleship Kirishima',
    'SH-YAMATO':  'Japanese battleship Yamato',
    'SH-NAGATO':  'Japanese battleship Nagato',
    'SH-MUTSU':   'Japanese battleship Mutsu',
    'SH-TONE':    'Japanese cruiser Tone (1937)',
    'SH-CHIKUMA': 'Japanese cruiser Chikuma (1938)',
    'SH-MOGAMI':  'Japanese cruiser Mogami (1934)',
    'SH-MIKUMA':  'Japanese cruiser Mikuma',
    'SH-SUZUYA':  'Japanese cruiser Suzuya (1934)',
    'SH-KUMANO':  'Japanese cruiser Kumano',
    'SH-NAGARA':  'Japanese cruiser Nagara',
    'SH-AKEBONO-MARU': 'Japanese oiler Akebono Maru',
    'SH-ARASHIO': 'Japanese destroyer Arashio',
    'SH-ASASHIO': 'Japanese destroyer Asashio (1936)',
    # --- USN ---
    'SH-CV6':     'USS Enterprise (CV-6)',
    'SH-CV5':     'USS Yorktown (CV-5)',
    'SH-HORNET':  'USS Hornet (CV-8)',
    'SH-NEWORLEANS':  'USS New Orleans (CA-32)',
    'SH-MINNEAPOLIS': 'USS Minneapolis (CA-36)',
    'SH-VINCENNES':   'USS Vincennes (CA-44)',
    'SH-NORTHAMPTON': 'USS Northampton (CA-26)',
    'SH-PENSACOLA':   'USS Pensacola (CA-24)',
    'SH-ASTORIA':     'USS Astoria (CA-34)',
    'SH-PORTLAND':    'USS Portland (CA-33)',
    'SH-ATLANTA':     'USS Atlanta (CL-51)',
    'SH-HAMMANN':     'USS Hammann (DD-412)',
    'SH-MIDWAY':      'Midway Atoll',
}


def thumb_url(title):
    """URL de la photo de tête de l'article, ~640px de large."""
    q = urllib.parse.urlencode({
        'action': 'query', 'titles': title, 'prop': 'pageimages',
        'piprop': 'thumbnail', 'pithumbsize': 640, 'format': 'json'})
    url = 'https://en.wikipedia.org/w/api.php?' + q
    req = urllib.request.Request(url, headers={'User-Agent': UA})
    pages = json.load(urllib.request.urlopen(req, timeout=20))['query']['pages']
    page = next(iter(pages.values()))
    return page.get('thumbnail', {}).get('source')


def download(url, dest):
    req = urllib.request.Request(url, headers={'User-Agent': UA})
    data = urllib.request.urlopen(req, timeout=30).read()
    with open(dest, 'wb') as f:
        f.write(data)
    return len(data)


def main():
    os.makedirs(OUT, exist_ok=True)
    ok = miss = skip = 0
    for sid, title in ARTICLES.items():
        dest = os.path.join(OUT, f'{sid}.jpg')
        if os.path.exists(dest) and not FORCE:
            skip += 1
            continue
        try:
            src = thumb_url(title)
            if not src:
                print(f'  no image  {sid}  ({title})')
                miss += 1
                continue
            n = download(src, dest)
            print(f'  ok {n//1024:>4} Ko  {sid}  <- {src.rsplit("/", 1)[-1]}')
            ok += 1
            time.sleep(1.5)  # courtoisie envers l'API Wikimedia (évite les 429)
        except Exception as e:
            print(f'  FAIL      {sid}  ({title}): {e}')
            miss += 1
    print(f'\nphotos: {ok} téléchargées, {skip} déjà présentes, {miss} manquantes -> {OUT}')


if __name__ == '__main__':
    main()
