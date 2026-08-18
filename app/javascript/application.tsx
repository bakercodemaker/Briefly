import React from "react";
import { createRoot } from "react-dom/client";

function ClientStatus() {
  return <span className="text-xs font-medium text-slate-500">Client workspace ready</span>;
}

function mountClientStatus() {
  const element = document.getElementById("briefly-client-status");

  if (element && !element.dataset.mounted) {
    createRoot(element).render(<ClientStatus />);
    element.dataset.mounted = "true";
  }
}

document.addEventListener("turbo:load", mountClientStatus);
mountClientStatus();
