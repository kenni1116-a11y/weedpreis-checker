import {
  formatCommunityPercent,
  type PublishedCommunityAverage,
} from '../../community/community-values'
import { CommunityPeopleIcon } from '../inventory/CommunityAverageCompact'

type CultivarProfileCommunityLineProps = {
  average: PublishedCommunityAverage | null
}

export function CultivarProfileCommunityLine({
  average,
}: CultivarProfileCommunityLineProps) {
  return (
    <div className="cultivar-community-line">
      <strong>Ø</strong>
      <CommunityPeopleIcon />
      <span>Community-Mittelwert</span>
      {average ? (
        <>
          <span>{formatCommunityPercent(average.thcMean, 'THC')}</span>
          <span>{formatCommunityPercent(average.cbdMean, 'CBD')}</span>
          <span>{average.contributorBand}</span>
        </>
      ) : (
        <span>Noch nicht genügend Community-Werte.</span>
      )}
    </div>
  )
}
