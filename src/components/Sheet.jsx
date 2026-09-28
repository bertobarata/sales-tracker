import { useEffect, useId, useRef } from 'react';

const FOCUSABLE = [
  'a[href]', 'button:not([disabled])', 'input:not([disabled])',
  'select:not([disabled])', 'textarea:not([disabled])', '[tabindex]:not([tabindex="-1"])',
].join(',');

/**
 * Folha vinda de baixo, o único padrão de sobreposição da app.
 *
 * Faz as quatro coisas que um overlay tem de fazer e que um `<div>` com posição fixa
 * não faz: anuncia-se como diálogo, prende o foco lá dentro, fecha no Escape e devolve
 * o foco a quem a abriu. Sem isto, quem navega por teclado entra no conteúdo por trás
 * do véu sem perceber que saiu da folha.
 */
export default function Sheet({ title, onClose, children, labelVisible = true }) {
  const sheetRef = useRef(null);
  const openerRef = useRef(null);
  const titleId = useId();

  useEffect(() => {
    openerRef.current = document.activeElement;

    // Impede o conteúdo por trás de fazer scroll enquanto a folha está aberta.
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';

    const node = sheetRef.current;
    const first = node?.querySelector(FOCUSABLE);
    (first ?? node)?.focus();

    function onKeyDown(e) {
      if (e.key === 'Escape') {
        e.stopPropagation();
        onClose();
        return;
      }
      if (e.key !== 'Tab' || !node) return;

      const items = Array.from(node.querySelectorAll(FOCUSABLE));
      if (items.length === 0) return;
      const firstItem = items[0];
      const lastItem = items[items.length - 1];

      if (e.shiftKey && document.activeElement === firstItem) {
        e.preventDefault();
        lastItem.focus();
      } else if (!e.shiftKey && document.activeElement === lastItem) {
        e.preventDefault();
        firstItem.focus();
      }
    }

    document.addEventListener('keydown', onKeyDown, true);
    return () => {
      document.removeEventListener('keydown', onKeyDown, true);
      document.body.style.overflow = previousOverflow;
      // O foco volta ao botão que abriu a folha, não ao início da página.
      if (openerRef.current instanceof HTMLElement) openerRef.current.focus();
    };
  }, [onClose]);

  return (
    <div
      className="sheet-overlay"
      onClick={e => { if (e.target === e.currentTarget) onClose(); }}
    >
      <div
        className="sheet"
        ref={sheetRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        tabIndex={-1}
      >
        <p id={titleId} className={labelVisible ? 'sheet-title' : 'visually-hidden'}>
          {title}
        </p>
        {children}
      </div>
    </div>
  );
}
