import { createContext, useContext, useState } from "react";

type Event = {
  id: string;
  title: string;
};

type EventContextType = {
  bookedEvents: Event[];
  bookEvent: (event: Event) => void;
};

const EventContext = createContext<EventContextType | null>(null);

export function EventProvider({ children }: { children: React.ReactNode }) {
  const [bookedEvents, setBookedEvents] = useState<Event[]>([]);

  const bookEvent = (event: Event) => {
    setBookedEvents((prev) =>
      prev.find((e) => e.id === event.id) ? prev : [...prev, event]
    );
  };

  return (
    <EventContext.Provider value={{ bookedEvents, bookEvent }}>
      {children}
    </EventContext.Provider>
  );
}

export function useEventStore() {
  const ctx = useContext(EventContext);
  if (!ctx) throw new Error("useEventStore must be used inside EventProvider");
  return ctx;
}
