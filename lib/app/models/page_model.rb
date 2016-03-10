# TODO: this belongs in pakyow/support
class String
  def self.slugify(string)
    string.downcase.gsub('  ', ' ').gsub(' ', '-').gsub(/[^a-z0-9-]/, '')
  end
end

module Pakyow
  module Console
    module Models
      class Page < Sequel::Model(:'pw-pages')
        one_to_many :content, as: :owner
        many_to_one :parent, class: self
        alias_method :page, :parent

        set_allowed_columns :name, :parent, :template

        def self.editables_for_view(view)
          view.doc.editables.each_with_index do |editable, i|
            id = editable[:doc].get_attribute(:'data-editable')
            id = i if id.nil? || id.empty?
            editable[:id] = id
          end
        end

        def validate
          validates_presence :name
          validates_presence :template# unless initial_value(:template).to_s == '__editable'

          # TODO: require unique slug (find a unique one automatically)
        end

        def after_create
          super

          return unless fully_editable?
          # TODO: this will go away once we can show containers right after selecting a template
          Pakyow.app.presenter.store(:default).template(template.to_sym).doc.containers.each do |container|
            container_name = container[0]

            content = {
              id: SecureRandom.uuid,
              scope: :content,
              type: :default,
              content: ''
            }

            add_content(content: [content], metadata: { id: container_name })
          end
        end

        def name=(value)
          super
          self.slug = String.slugify(value)
        end

        def relation_name
          name
        end

        def matches?(path)
          # TODO: this needs to be smart enough to handle parent
          String.normalize_path(path) == slug
        end

        def published?
          published == true
        end

        def editables
          self.class.editables_for_view(Pakyow.app.presenter.store(:default).view(slug))
        end

        def content_for(editable_id)
          content_dataset.where("metadata ->> 'id' = '#{editable_id}'").first
        end

        def content
          content_dataset.first.content
        end

        def template
          template = @values[:template]

          if template == '__editable'
            composer = Pakyow.app.presenter.store(:default).composer(slug)
            composer.template.name
          else
            template
          end
        end

        def template=(value)
          return unless fully_editable?
          super
        end

        def fully_editable?
          @values[:template] != '__editable'
        end
      end
    end
  end
end

Pakyow::Console::Models::Page.plugin :dirty

# TODO: move to a more logical place
Pakyow::Console.after :page, :create do
  puts 'invalidating'
  Pakyow::Console.invalidate_pages
end

Pakyow::Console.after :page, :update do
  puts 'invalidating'
  Pakyow::Console.invalidate_pages
end

Pakyow::Console.after :page, :delete do
  puts 'invalidating'
  Pakyow::Console.invalidate_pages
end