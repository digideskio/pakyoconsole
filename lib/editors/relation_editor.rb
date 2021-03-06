Pakyow::Console.editor :relation do |options, related_datum, attribute, datum, datum_type|
  view = Pakyow::Presenter::ViewContext.new(presenter.store(:console).partial('console/editors', :relation).dup, self)
  editor = view.scope(:editor)[0]
  editor.scoped_as = :datum

  view.component(:modal).with do
    # disallow self-referential relationships
    if attribute[:name] == datum_type.name
      remove
    else
      attrs.href = router.group(:data).path(:show, data_id: attribute[:name])
    end
  end

  related_class = attribute[:extras][:class]
  related_name = attribute[:extras][:relationship] || attribute[:name]
  object_id = datum ? datum[:id] : nil

  editor.mutate(
    :list_relations,
    with: data(:datum).for_relation(related_class, related_name, datum_type.model, object_id)
  ).subscribe

  view.instance_variable_get(:@view)
end
