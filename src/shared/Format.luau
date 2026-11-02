-- Números cortos: 1.2K, 3.4M...
local suffixes = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx" }

return function(n: number): string
	local i = 1
	while math.abs(n) >= 1000 and i < #suffixes do
		n /= 1000
		i += 1
	end
	if i == 1 then
		return tostring(math.floor(n))
	end
	return string.format("%.1f", n):gsub("%.0$", "") .. suffixes[i]
end
