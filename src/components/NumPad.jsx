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

  const keys = ['1','2','3','4','5','6','7','8','9','C','0','⌫'];

  return (
    <div className="numpad">
      <div className="numpad-display">
        <span className="numpad-value">{value === '' ? '0' : value}</span>
      </div>
      <div className="numpad-grid">
        {keys.map(k => (
          <button
            key={k}
            type="button"
            className={`numpad-key ${k === 'C' ? 'key-clear' : ''} ${k === '⌫' ? 'key-del' : ''}`}
            onClick={() => {
              if (k === '⌫') del();
              else if (k === 'C') clear();
              else press(k);
            }}
          >
            {k}
          </button>
        ))}
      </div>
      <button type="button" className="numpad-confirm" onClick={onConfirm}>
        {confirmLabel}
      </button>
    </div>
  );
}
