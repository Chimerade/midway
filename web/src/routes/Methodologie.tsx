import { useEffect, useState } from 'react';
import { useLang } from '../i18n/LanguageContext';

export default function Methodologie() {
  const { lang, t } = useLang();
  const [html, setHtml] = useState('');
  useEffect(() => {
    let alive = true;
    fetch(`${import.meta.env.BASE_URL}data/methodologie.${lang}.html`)
      .then((r) => { if (!r.ok) throw new Error(`HTTP ${r.status}`); return r.text(); })
      .then((txt) => { if (alive) setHtml(txt); })
      .catch(() => { if (alive) setHtml(`<p>${t('method_unavailable')}</p>`); });
    return () => { alive = false; };
  }, [lang, t]);
  return <div className="page" dangerouslySetInnerHTML={{ __html: html }} />;
}
