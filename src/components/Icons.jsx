/**
 * Um só vocabulário de ícones: traço de 1.75, grelha de 24, cantos e pontas redondos,
 * cor herdada do texto. Emoji não servia — muda de desenho em cada plataforma, não
 * herda cor, e os leitores de ecrã liam "lápis" antes do nome do separador.
 */
function Svg({ children }) {
  return (
    <svg
      viewBox="0 0 24 24"
      width="20"
      height="20"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.75"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      focusable="false"
    >
      {children}
    </svg>
  );
}

// Hoje: escrever o dia.
export const IconToday = () => (
  <Svg><path d="M4 20h16" /><path d="M14.5 4.5a2.1 2.1 0 0 1 3 3L9 16l-4 1 1-4Z" /></Svg>
);

// Semana: os totais lado a lado.
export const IconWeek = () => (
  <Svg><path d="M4 20V10" /><path d="M10 20V4" /><path d="M16 20v-7" /><path d="M22 20H2" /></Svg>
);

// Relatório: o texto pronto a enviar.
export const IconReport = () => (
  <Svg>
    <path d="M6 3h9l5 5v13a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1Z" />
    <path d="M14 3v6h6" /><path d="M9 14h7" /><path d="M9 18h5" />
  </Svg>
);

// Tendências: a série ao longo dos meses.
export const IconTrends = () => (
  <Svg><path d="M3 17l5.5-5.5 3.5 3.5L21 6" /><path d="M15 6h6v6" /></Svg>
);

// Configurações: os objetivos que se afinam.
export const IconSettings = () => (
  <Svg>
    <path d="M5 8h14" /><path d="M5 16h14" />
    <circle cx="10" cy="8" r="2.2" /><circle cx="15" cy="16" r="2.2" />
  </Svg>
);

export const IconClose = () => (
  <Svg><path d="M6 6l12 12" /><path d="M18 6L6 18" /></Svg>
);

export const IconClock = () => (
  <Svg><circle cx="12" cy="12" r="8.5" /><path d="M12 7.5V12l3 2" /></Svg>
);
