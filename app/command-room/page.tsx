import type { Metadata } from 'next'
import { CommandRoomView } from '@/components/command-room/command-room-view'

export const metadata: Metadata = {
  title: 'Command Room · ResQ Command',
  description:
    'Projector-ready situation-room wall view for active disaster events across Gujarat.',
}

export default function CommandRoomPage() {
  return <CommandRoomView />
}
