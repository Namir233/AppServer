#!/usr/bin/ruby

Preview=0

def fix_opencv_lib_link(file,rlib)
    if(rlib.include?('namir'))
        name = rlib.split('/').last
        cmd = "install_name_tool -change #{rlib} @executable_path/dylibs/#{name} #{file}"
        if Preview == 1
            puts "Preivew: #{cmd}"
        else
            `#{cmd}`
        end
    else 
        puts "ignore rlib: #{rlib}";
    end
end

def fix_file_rely_lib(file)
  puts "===============start change #{file}==============="
  linklibs = `otool -L #{file}`.split("\n")
  linklibs.delete_at(0)
  linklibs.each_with_index do |rlib,i|
    rlib = rlib.split()[0]
    fix_opencv_lib_link(file,rlib)
  end
end

def doopencvlist
  # puts "Preview: #{Preview}"
  `ls |grep namir`.split().each_with_index do |file,i|
    fix_file_rely_lib(file)
  end
end

def viewlib(file)
    puts `otool -L #{file}`
end

if __FILE__ == $0
  fix_file_rely_lib(ARGV[0])
end