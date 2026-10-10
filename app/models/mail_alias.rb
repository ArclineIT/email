# An address that forwards to one or more others. Named MailAlias because
# "alias" is a Ruby keyword; the table is plain "aliases".
class MailAlias < ApplicationRecord
  self.table_name = "aliases"

  include HasAddress

  MAX_DESTINATIONS = 50

  normalizes :destinations, with: ->(list) { list.to_s.split(/[\s,;]+/).map(&:downcase).compact_blank.uniq.join(",") }

  validate :destinations_are_addresses

  def destination_list = destinations.to_s.split(",")

  private
    def destinations_are_addresses
      list = destination_list
      return errors.add(:destinations, "must list at least one address") if list.empty?
      return errors.add(:destinations, "may list at most #{MAX_DESTINATIONS} addresses") if list.size > MAX_DESTINATIONS

      bad = list.grep_v(URI::MailTo::EMAIL_REGEXP)
      errors.add(:destinations, "has an invalid address: #{bad.first.truncate(60)}") if bad.any?
      errors.add(:destinations, "cannot forward to itself") if list.include?(address)
    end
end
