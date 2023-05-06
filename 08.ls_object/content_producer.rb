# frozen_string_literal: true

module ContentProducer
  def fetch_contents(dir_path, options)
    contents = []
    return contents << dir_path if FileTest.file?(dir_path)
    return unless Dir.exist?(dir_path)
    if options['a']
      contents = Dir.glob('*', File::FNM_DOTMATCH, base: dir_path)
      contents.insert(1, '..')
    else
      contents = Dir.glob('*', base: dir_path)
    end
    contents.reverse! if options['r']
    contents
  end
end