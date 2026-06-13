import { NavLink } from 'react-router-dom';
import { useTheme } from '../theme/ThemeContext';

const link = ({ isActive }: { isActive: boolean }) => (isActive ? 'active' : '');

export default function Nav() {
  const { theme, toggle } = useTheme();
  return (
    <nav className="mainnav">
      <strong>MIDWAY 1942</strong>
      <NavLink to="/" end className={link}>Accueil</NavLink>
      <NavLink to="/carte" className={link}>Carte</NavLink>
      <NavLink to="/chronologie" className={link}>Chronologie</NavLink>
      <NavLink to="/methodologie" className={link}>Méthodologie</NavLink>
      <span className="spacer" />
      <button onClick={toggle}>{theme === 'light' ? '🌙 sombre' : '☀ clair'}</button>
    </nav>
  );
}
