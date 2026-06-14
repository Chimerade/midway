import { Link } from 'react-router-dom';
import { useLang } from '../i18n/LanguageContext';

export default function Home() {
  const { t } = useLang();
  return (
    <div className="page">
      <h1>{t('home_title')}</h1>
      <p>{t('home_intro')}</p>
      <ul>
        <li><Link to="/carte">{t('home_map')}</Link> — {t('home_map_desc')}</li>
        <li><Link to="/chronologie">{t('home_chrono')}</Link> — {t('home_chrono_desc')}</li>
        <li><Link to="/methodologie">{t('home_method')}</Link> — {t('home_method_desc')}</li>
      </ul>
    </div>
  );
}
