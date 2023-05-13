# frozen_string_literal: true

module ContentProducer
  private

  def fetch_contents(dir_path, options)
    target_contents = []
    return [dir_path] if FileTest.file?(dir_path)

    return unless Dir.exist?(dir_path)

    if options['a']
      target_contents = Dir.glob('*', File::FNM_DOTMATCH, base: dir_path)
      target_contents.insert(1, '..')
    else
      target_contents = Dir.glob('*', base: dir_path)
    end
    target_contents.reverse! if options['r']
    target_contents
  end
end
