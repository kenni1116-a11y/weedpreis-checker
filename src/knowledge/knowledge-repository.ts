import type { KnowledgeGraph } from './knowledge-graph'

export type KnowledgeRepository = {
  loadGraph(signal?: AbortSignal): Promise<KnowledgeGraph | null>
}
