class RvmRubyRunner  
  def self.run(ruby_string)
    output = `rvm use #{ruby_string}@dbf --create; bundle install; rspec`
    puts output if ENV['DEBUG=1']
    if output =~ /To install do/
      "#{ruby_string.rjust 12}: not installed"
    elsif output =~ /Finished/m
      results = output.lines.to_a[-1].strip
      time = output.lines.to_a[-2].strip
      "#{ruby_string.rjust 12}: #{results}, #{time}"
    end
  end
end