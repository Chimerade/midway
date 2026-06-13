import { Routes, Route } from 'react-router-dom';
import Layout from './layout/Layout';
import Home from './routes/Home';
import Carte from './routes/Carte';
import Methodologie from './routes/Methodologie';
import Chronologie from './routes/Chronologie';

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<Layout />}>
        <Route index element={<Home />} />
        <Route path="carte" element={<Carte />} />
        <Route path="chronologie" element={<Chronologie />} />
        <Route path="methodologie" element={<Methodologie />} />
        <Route path="*" element={<div className="page">Page introuvable</div>} />
      </Route>
    </Routes>
  );
}
