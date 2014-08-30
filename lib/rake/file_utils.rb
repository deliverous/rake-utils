require 'fileutils'

module FileUtils
  def copy_if_obsolete(src, target)
    unless FileUtils.uptodate?(target, [src]) 
      cp_r src, target
    end
  end    
end