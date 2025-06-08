const prowlarrIndices = [
	1, // seedpool
	3, // AvistaZ
	9, // PTCafe
	10, //CHDBits
	11, // ICC2022
	12, // PTFans
	13, // LST
	14, // Oldtoons
	15, // PT GTK
	16, // DiscFan
	17, // DigitalCore
	18, // Milkie
];

module.exports = {
	action: "inject",
	apiKey: "{{ .CROSS_SEED_API_KEY }}",
	delay: 30,
	includeEpisodes: true,
	includeNonVideos: true,
	includeSingleEpisodes: true,
	linkCategory: "xseeds",
	linkDirs: ["/Media/Downloads/bt/complete/xseeds"],
	linkType: "hardlink",
	qbittorrentUrl: "http://qbittorrent.media.svc.cluster.local:10095",
	radarr: [
		"http://radarr.media.svc.cluster.local:7878/radarr?apikey={{ .RADARR_API_KEY }}",
	],
	skipRecheck: true,
	sonarr: [
		"http://sonarr.media.svc.cluster.local:8989/sonarr?apikey={{ .SONARR_API_KEY }}",
	],
	torznab: prowlarrIndices.map(
		(i) =>
			`http://prowlarr.media.svc.cluster.local:9696/prowlarr/${i}/api?apikey={{ .PROWLARR_API_KEY }}`,
	),
	useClientTorrents: true,
};
