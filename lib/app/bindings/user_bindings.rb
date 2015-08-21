Pakyow::App.bindings :'pw-user' do
  scope :'pw-user' do
    restful :'pw-user'

    binding :'edit-href' do
      { href: router.group(:'pw-user').path(:edit, :'pw-user_id' => bindable.id) }
    end

    binding :role do
      {
        content: bindable[:role],
        class: lambda { |c| c.ensure(bindable[:role])}
      }
    end

    binding :'avatar-small' do
      {
        src: gravatar_url(Digest::MD5.hexdigest(bindable[:email]))
      }
    end
  end
end
