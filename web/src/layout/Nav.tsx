import { NavLink } from 'react-router-dom';
import { useTheme } from '../theme/ThemeContext';
import { useLang } from '../i18n/LanguageContext';

const link = ({ isActive }: { isActive: boolean }) => (isActive ? 'active' : '');

export default function Nav() {
  const { theme, toggle } = useTheme();
  const { lang, setLang, t } = useLang();
  return (
    <nav className="mainnav">
      <strong>MIDWAY 1942</strong>
      <NavLink to="/" end className={link}>{t('nav_home')}</NavLink>
      <NavLink to="/carte" className={link}>{t('nav_map')}</NavLink>
      <NavLink to="/chronologie" className={link}>{t('nav_chronology')}</NavLink>
      <NavLink to="/methodologie" className={link}>{t('nav_methodology')}</NavLink>
      <span className="spacer" />
      <button
        onClick={() => setLang(lang === 'en' ? 'fr' : 'en')}
        title={lang === 'en' ? 'Passer en français' : 'Switch to English'}
      >
        {lang === 'en' ? 'FR' : 'EN'}
      </button>
      <button onClick={toggle}>{theme === 'light' ? t('theme_to_dark') : t('theme_to_light')}</button>
    </nav>
  );
}
