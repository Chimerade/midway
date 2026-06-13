import { useEffect, useState } from 'react';

export default function Methodologie() {
  const [html, setHtml] = useState('');
  useEffect(() => {
    fetch(`${import.meta.env.BASE_URL}data/methodologie.html`)
      .then((r) => r.text()).then(setHtml).catch(() => setHtml('<p>Contenu indisponible.</p>'));
  }, []);
  return <div className="page" dangerouslySetInnerHTML={{ __html: html }} />;
}
