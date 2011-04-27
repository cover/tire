require 'rake'
require 'benchmark'

namespace :slingshot do

  usage = <<-DESC
          Import data from your ActiveModel model: rake environment slingshot:import CLASS='MyModel'

          Pass params for the `paginate` method:
            $ rake environment slingshot:import CLASS='Article' PARAMS='{:page => 1}'

          Force rebuilding the index (delete and create):
            $ rake environment slingshot:import CLASS='Article' PARAMS='{:page => 1}' FORCE=1
    
  DESC

  desc usage.split("\n").first.to_s
  task :import do

    def elapsed_to_human(elapsed)
      hour = 60*60
      day  = hour*24

      case elapsed
      when 0..59
        "#{sprintf("%1.5f", elapsed)} seconds"
      when 60..hour-1
        "#{elapsed/60} minutes and #{elapsed % 60} seconds"
      when hour..day
        "#{elapsed/hour} hours and #{elapsed % hour} minutes"
      else
        "#{elapsed/hour} hours"
      end
    end

    if ENV['CLASS'].to_s == ''
      puts '='*80, 'USAGE', '='*80, usage.gsub(/          /, '')
      exit(1)
    end

    klass  = eval(ENV['CLASS'].to_s)
    params = eval(ENV['PARAMS'].to_s) || {}

    if ENV['FORCE']
      puts "[IMPORT] Deleting index '#{klass.index.name}'"
      klass.index.delete
      puts "[IMPORT] Creating index '#{klass.index.name}' with mapping:",
           Yajl::Encoder.encode(klass.mapping_to_hash, :pretty => true)
      klass.index.create :mappings => klass.mapping_to_hash
    end

    STDOUT.sync = true
    puts "[IMPORT] Starting import for the '#{ENV['CLASS']}' class"
    tty_cols = 80
    total    = klass.count rescue nil
    done     = 0

    STDOUT.puts '-'*tty_cols
    elapsed = Benchmark.realtime do
      klass.import(params) do |documents|

        if total
          done += documents.size

          # I CAN HAZ PROGREZ BAR LIEK HOMEBRU!
          percent  = ( (done.to_f / total) * 100 ).to_i
          STDOUT.print( ("#" * ( percent*((tty_cols-4).to_f/100)).to_i )+" ")
          STDOUT.print("\r"*tty_cols+"#{percent}% ")
        end

        # Don't forget to return the documents collection here
        documents
      end
    end

    puts "", '='*80, "Import finished in #{elapsed_to_human(elapsed)}"

  end
end