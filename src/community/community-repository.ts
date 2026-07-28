import type {
  OwnCommunityContribution,
  PublishedCommunityAverage,
  ValidCommunityContribution,
} from './community-values'

export type CommunityRepository = {
  getOwn(
    cultivarId: string,
    signal?: AbortSignal,
  ): Promise<OwnCommunityContribution | null>
  getPublished(
    cultivarId: string,
    signal?: AbortSignal,
  ): Promise<PublishedCommunityAverage | null>
  upsert(
    input: ValidCommunityContribution,
  ): Promise<OwnCommunityContribution>
  remove(cultivarId: string): Promise<void>
}
