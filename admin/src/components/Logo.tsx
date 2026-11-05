export function EpayMark({ size = 36 }: { size?: number }) {
  const r = size * 0.235;
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 100 100"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      aria-hidden
    >
      <defs>
        <linearGradient id="epay-bg" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="#2E9BF0" />
          <stop offset="100%" stopColor="#0E3C9B" />
        </linearGradient>
      </defs>
      <rect width="100" height="100" rx={(r / size) * 100} fill="url(#epay-bg)" />
      {/* E */}
      <rect x="21" y="26" width="10.5" height="48" rx="5.25" fill="#fff" />
      <rect x="21" y="26" width="35" height="10.5" rx="5.25" fill="#fff" />
      <rect x="21" y="44.75" width="26" height="10.5" rx="5.25" fill="#fff" />
      <rect x="21" y="63.5" width="35" height="10.5" rx="5.25" fill="#fff" />
      {/* rising arrow */}
      <line
        x1="60"
        y1="73"
        x2="75.1"
        y2="38.3"
        stroke="#5CC8F5"
        strokeWidth="8"
        strokeLinecap="round"
      />
      <path d="M80 27 L82.73 44.55 L65.31 36.97 Z" fill="#5CC8F5" />
    </svg>
  );
}

export function EpayWordmark({ size = 34 }: { size?: number }) {
  return (
    <div className="flex items-center gap-2.5">
      <EpayMark size={size} />
      <span
        className="font-extrabold tracking-tight"
        style={{ fontSize: size * 0.62 }}
      >
        <span className="text-sky-500">E</span>
        <span className="text-slate-900">Pay</span>
      </span>
    </div>
  );
}

export function EpayWordmarkDark({ size = 34 }: { size?: number }) {
  return (
    <div className="flex items-center gap-2.5">
      <EpayMark size={size} />
      <span
        className="font-extrabold tracking-tight"
        style={{ fontSize: size * 0.62 }}
      >
        <span className="text-sky-300">E</span>
        <span className="text-white">Pay</span>
      </span>
    </div>
  );
}
