import { Link } from 'react-router-dom';

export default function Home() {
  return (
    <div className="page">
      <h1>Bataille de Midway — 3 au 7 juin 1942</h1>
      <p>Reconstitution chronologique et cartographique de la bataille à partir d'une base
        de données de sources, positions inférées et processus modélisés.</p>
      <ul>
        <li><Link to="/carte">Carte / Replay animé</Link> — rejouer la bataille dans le temps</li>
        <li><Link to="/chronologie">Chronologie</Link> — la liste des événements</li>
        <li><Link to="/methodologie">Méthodologie</Link> — comment le modèle est construit</li>
      </ul>
    </div>
  );
}
