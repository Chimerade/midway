import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';
import { STRINGS, type Lang, type StringKey } from './strings';

const KEY = 'midway-lang';

function initialLang(): Lang {
  try {
    const s = localStorage.getItem(KEY);
    if (s === 'en' || s === 'fr') return s;
  } catch { /* localStorage unavailable */ }
  return 'en'; // English by default (international public repo)
}

const Ctx = createContext<{ lang: Lang; setLang: (l: Lang) => void; t: (k: StringKey) => string }>({
  lang: 'en', setLang: () => {}, t: (k) => STRINGS.en[k],
});

export function LanguageProvider({ children }: { children: ReactNode }) {
  const [lang, setLangState] = useState<Lang>(initialLang);
  useEffect(() => { document.documentElement.lang = lang; }, [lang]);
  const setLang = (l: Lang) => {
    setLangState(l);
    try { localStorage.setItem(KEY, l); } catch { /* ignore */ }
  };
  const t = (k: StringKey) => STRINGS[lang][k];
  return <Ctx.Provider value={{ lang, setLang, t }}>{children}</Ctx.Provider>;
}

export const useLang = () => useContext(Ctx);
