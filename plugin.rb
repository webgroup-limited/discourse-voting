# name: discourse-feature-voting
# about: Adds the ability to vote on features in a specified category.
# version: 0.1
# author: Joe Buhlig joebuhlig.com
# url: https://www.github.com/joebuhlig/discourse-feature-voting

register_asset "stylesheets/feature-voting.scss"
register_asset "javascripts/feature-voting.js"

enabled_site_setting :feature_voting_enabled

# load the engine
load File.expand_path('../lib/discourse_feature_voting/engine.rb', __FILE__)

after_initialize do

  require_dependency 'topic_view_serializer'
  class ::TopicViewSerializer
    attributes :can_vote, :single_vote, :vote_count, :user_voted

    def can_vote
      return object.topic.category.custom_fields["enable_topic_voting"]
    end

    def single_vote
      if object.topic.vote_count.to_i == 1
        return true
      else
        return false
      end
    end

    def vote_count
      object.topic.vote_count
    end

    def user_voted
      user = scope.user
      if user && user.custom_fields["votes"]
          user_votes = user.custom_fields["votes"]
          return user_votes.include? object.topic.id.to_s
      else
        return false
      end
    end

  end

  class ::Category
      after_save :reset_voting_cache

      protected
      def reset_voting_cache
        ::Guardian.reset_voting_cache
      end
  end

  class ::Guardian

    @@allowed_voting_cache = DistributedCache.new("allowed_voting")

    def self.reset_voting_cache
      @@allowed_voting_cache["allowed"] =
        begin
          Set.new(
            CategoryCustomField
              .where(name: "enable_topic_voting", value: "true")
              .pluck(:category_id)
          )
        end
    end
  end


  require_dependency 'user'
  class ::User

      def vote_count
        if self.custom_fields["votes"]
          user_votes = self.custom_fields["votes"]
          return user_votes.length
        else 
          return 0
        end
      end

      def votes
        if self.custom_fields["votes"]
          return self.custom_fields["votes"]
        else
          return [nil]
        end
      end

  end

  require_dependency 'topic'
  class ::Topic
    def vote_count
      if self.custom_fields["vote_count"]
        return self.custom_fields["vote_count"]
      else
        if self.category.custom_fields["enable_topic_voting"]
          Set.new(
            TopicCustomField
              .where(name: "vote_count", value: 0)
              .pluck(:topic_id)
          )
        end
        return 0
      end
    end
  end

  Discourse::Application.routes.append do
    mount ::DiscourseFeatureVoting::Engine, at: "/voting"
  end
end