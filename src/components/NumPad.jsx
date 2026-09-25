export default function NumPad({ value, onChange, onConfirm, confirmLabel }) {
  function press(digit) {
    const next = value === '' ? digit : value + digit;
    onChange(String(parseInt(next, 10))); // remove leading zeros
  }

  function del() {
    onChange(value.slice(0, -1));
  }

  function clear() {
    onChange('');
  }

  // Os digitos leem-se sozinhos. "C" e "⌫" nao: um leitor de ecra diz "ce" e, no
  // caso do U+232B, ou diz algo imprevisivel ou nao diz nada. Dai o nome explicito.
  const keys = [
    { k: '1' }, { k: '2' }, { k: '3' },
    { k: '4' }, { k: '5' }, { k: '6' },
    { k: '7' }, { k: '8' }, { k: '9' },
    { k: 'C', label: 'Limpar', className: 'key-clear' },
    { k: '0' },
    { k: '⌫', label: 'Apagar último dígito', className: 'key-del' },
  ];

  return (
    <div className="numpad">
      <div className="numpad-display" role="status" aria-live="polite" aria-atomic="true">
        <span className="numpad-value">{value === '' ? '0' : value}</span>
      </div>
      <div className="numpad-grid" role="group" aria-label="Teclado numérico">
        {keys.map(({ k, label, className }) => (
          <button
            key={k}
            type="button"
            className={`numpad-key ${className ?? ''}`}
            aria-label={label}
            onClick={() => {
              if (k === '⌫') del();
              else if (k === 'C') clear();
              else press(k);
            }}
          >
            <span aria-hidden={label ? 'true' : undefined}>{k}</span>
          </button>
        ))}
      </div>
      <button type="button" className="numpad-confirm" onClick={onConfirm}>
        {confirmLabel}
      </button>
    </div>
  );
}
