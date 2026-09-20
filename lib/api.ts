const BASE_URL = "http://127.0.0.1:8000";

export async function getIncidents() {
  const res = await fetch(`${BASE_URL}/incidents`);
  return res.json();
}

export async function detectDuplicate(description: string) {
  const res = await fetch(`${BASE_URL}/detect-duplicate`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      description,
    }),
  });

  return res.json();
}

export async function encodeText(text: string) {
  const res = await fetch(
    `${BASE_URL}/encode?text=${encodeURIComponent(text)}`
  );

  return res.json();
}