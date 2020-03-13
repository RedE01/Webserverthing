class Pair
    attr_reader :var1, :var2

    def initialize(var1, var2) 
        @var1 = var1
        @var2 = var2
    end
end

def getTimeElapsedStr(startTime)
    time_diff = (Time.now().to_i() - startTime.to_time().to_i())

    if(time_diff < 60)
        return time_diff.to_s() + " seconds ago"
    end

    if(time_diff < 3600)
        return (time_diff / 60).round().to_s() + " minutes ago"
    end

    if(time_diff < 86400)
        return (time_diff / 3600).round().to_s() + " hours ago"
    end

    return (time_diff / 86400).round().to_s() + " days ago"
end