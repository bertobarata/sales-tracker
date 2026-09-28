import { useSyncExternalStore } from 'react';

const QUERY = '(pointer: coarse)';

/**
 * Responde à pergunta certa: o dedo ou o rato?
 *
 * A app decidia isto com uma regex sobre o user-agent, avaliada uma vez no carregamento
 * do módulo e copiada por três ficheiros. Isso errava em todos os casos interessantes —
 * iPad em modo desktop apanhava o teclado próprio, portátil com ecrã tátil não apanhava,
 * e redimensionar a janela não mudava nada porque o valor já estava congelado.
 *
 * `pointer: coarse` pergunta ao dispositivo o que o dispositivo sabe, e reage se mudar
 * (rato ligado a um tablet, por exemplo).
 */
function subscribe(onChange) {
  const mq = window.matchMedia(QUERY);
  mq.addEventListener('change', onChange);
  return () => mq.removeEventListener('change', onChange);
}

function getSnapshot() {
  return window.matchMedia(QUERY).matches;
}

// No servidor não há ponteiro nenhum; assume-se rato e o cliente corrige no primeiro render.
function getServerSnapshot() {
  return false;
}

export function useCoarsePointer() {
  return useSyncExternalStore(subscribe, getSnapshot, getServerSnapshot);
}
