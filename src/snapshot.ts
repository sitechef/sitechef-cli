interface SiteChefImage {
	id: string;
	description: string;
	image: {
		focus: {
			x: string;
			y: string;
		};
		large: {
			src: string;
		};
		mobile: {
			src: string;
		};
		thumbnail: {
			src: string;
		};
		raw: {
			src: string | false;
		};
	};
	slug: string;
	tags: string;
	type: 'image' | 'youtube' | 'vimeo' | 'html5';
	video: unknown;
	videoData: unknown;
}

export interface AbridgedSiteChefCategory<CustomFields = null> {
	body: string;
	featuredImage: SiteChefImage | null;
	customFields: CustomFields;
	description: string;
	htmlTitle: string;
	id: string;
	items: SiteChefImage[];
	metaDescription: string;
	parent: {
		id: string;
	};
	name: string;
	rawBody: string;
}

export type RootContents = {
	preferences: Record<string, string>;
	imageRoot: string;
	content: AbridgedSiteChefCategory;
	environment: 'production' | 'development';
};
type PageIndexes = Record<string, RootContents>;

export type Snapshot = {
	'/': RootContents;
} & PageIndexes;
