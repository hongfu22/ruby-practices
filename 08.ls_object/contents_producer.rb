# frozen_string_literal: true

module ContentsProducer
  private

  def fetch_contents(input_target, options)
    target_contents = []
    return [input_target] if FileTest.file?(input_target)

    return nil unless Dir.exist?(input_target)

    if options['a']
      target_contents = Dir.glob('*', File::FNM_DOTMATCH, base: input_target)
      target_contents.insert(1, '..')
    else
      target_contents = Dir.glob('*', base: input_target)
    end
    target_contents.reverse! if options['r']
    target_contents
  end
end
