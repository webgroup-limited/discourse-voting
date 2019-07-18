# frozen_string_literal: true

class ReclaimFromDisabledCategory < ActiveRecord::Migration[5.2]
  def up
    aliases = {
      votes: DiscourseVoting::VOTES,
      votes_archive: DiscourseVoting::VOTES_ARCHIVE,
      voting_enabled: DiscourseVoting::VOTING_ENABLED
    }

    # archive votes in non-voting categories
    DB.exec(<<~SQL, aliases)
      UPDATE user_custom_fields ucf
      SET name = :votes_archive
      FROM topics t
      WHERE ucf.name = :votes
      AND t.id::text = ucf.value
      AND t.category_id NOT IN (
        SELECT category_id FROM category_custom_fields WHERE name=:voting_enabled AND value='true'
      )
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
