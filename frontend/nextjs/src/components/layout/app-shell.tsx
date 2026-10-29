import type { ReactNode } from "react";
import { Panel } from "@/components/ui/panel";

export function AppShell({ children }: { children: ReactNode }) {
  return (
    <main>
      <Panel>{children}</Panel>
    </main>
  );
}
