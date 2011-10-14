require 'zlib'

module TinyQ
    class Permanent


        def self.store obj, filename, options = {}
            dump = Marshal.dump(obj)
            file = File.new(filename, 'w')
            file = Zlib::GzipWriter.new(file) unless options[:gzip] == false
            file.write dump
            file.close
            return obj
        end

        def self.load filename
            begin
                file = Zlib::GzipReader.open(filename)
            rescue Zlib::GzipFile::Error
                file = File.open(filename, 'r')
            ensure
                obj = Marshal.load file.read
                file.close
                return obj
            end
        end

        def self.remove filename
            File.delete(file)
        end

    end
end
