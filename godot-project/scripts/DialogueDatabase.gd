extends RefCounted

const DATA: Dictionary = {
	"honoka": {
		"name": "ほのか",
		"first_meet": [
			{"speaker": "ほのか", "text": "おはよう！ …って、あれ？"},
			{"speaker": "ほのか", "text": "ねえ、視点高くない？ また少し伸びた？"},
			{"speaker": "ほのか", "text": "あはは、見上げすぎて首が痛くなっちゃいそう。"},
			{"speaker": "ほのか", "text": "私、ほのか。改めてよろしくね。"},
		],
		"tall": [
			{"speaker": "ほのか", "text": "あ、ほら。また私を肘置きにしようとしてるでしょ！"},
			{"speaker": "ほのか", "text": "でも、人混みでもすぐ見つけられるから便利かも。"},
		],
		"huge": [
			{"speaker": "ほのか", "text": "（見上げながら）……もう、どこまで伸びるの？"},
			{"speaker": "ほのか", "text": "たまには屈んでよ。内緒話もできないじゃない。"},
		],
		"measure_invite": [
			{"speaker": "ほのか", "text": "ねえ……また背、伸びてない？"},
			{
				"speaker": "ほのか",
				"text": "保健室、行こうよ。…正直、最近どんな気持ち？",
				"choices": [
					{"label": "ちょっと嬉しいかも", "next": "measure_invite_proud", "emotion": "confidence"},
					{"label": "目立つし、恥ずかしい……", "next": "measure_invite_shy", "emotion": "complex"},
					{"label": "よくわからない", "next": "measure_invite_unsure"},
				]
			},
		],
		"measure_invite_proud": [
			{"speaker": "（主人公）", "text": "うん……ちょっと誇らしい気がする。"},
			{"speaker": "ほのか", "text": "そっか！ 似合ってるよ、その高さ。"},
			{"speaker": "ほのか", "text": "じゃあ行こ！ 何センチか確かめてこよう。"},
		],
		"measure_invite_shy": [
			{"speaker": "（主人公）", "text": "……正直、目立って恥ずかしくて。"},
			{"speaker": "ほのか", "text": "気にしないって！ みんな気にしてないよ。"},
			{"speaker": "ほのか", "text": "ほら、一緒に行けば怖くない。行こっ。"},
		],
		"measure_invite_unsure": [
			{"speaker": "（主人公）", "text": "……うーん、自分でもよくわかんない。"},
			{"speaker": "ほのか", "text": "そっか。まず測ってみようよ。"},
			{"speaker": "ほのか", "text": "数字で見ると、なんか気持ちが整理できるかもよ？"},
		],
		"measure_after": [
			{"speaker": "ほのか", "text": "……やっぱり伸びてる。"},
			{"speaker": "ほのか", "text": "次の学期も、また測ろうね。抜け駆け禁止だよ！"},
		],
		"vball_join_cheer": [
			{"speaker": "ほのか", "text": "バレー部！？ えっ、すごい決断だね。"},
			{"speaker": "ほのか", "text": "絶対似合うって。思いっきり活躍してよ！"},
		],
		"vball_pain_consult": [
			{"speaker": "（主人公）", "text": "……ほのか、ちょっと聞いてもいい？ 最近、脚が痛くて。"},
			{"speaker": "ほのか", "text": "え、大丈夫？ それって練習のしすぎじゃないかな。"},
			{
				"speaker": "ほのか",
				"text": "先輩に話した方がいいよ。ね、どうする？",
				"choices": [
					{"label": "先輩に伝えてもらう", "next": "pain_tell_senior", "action": "vball_pain_report"},
					{"label": "しばらく自分で頑張る", "next": "pain_endure"},
				]
			},
		],
		"pain_tell_senior": [
			{"speaker": "ほのか", "text": "わかった、私から先輩に話しておくね。"},
			{"speaker": "ほのか", "text": "無理しないで。体が一番大事だよ。"},
		],
		"pain_endure": [
			{"speaker": "ほのか", "text": "……わかった。でも限界が来たら必ず言ってね。"},
		],
		"haruka_after_summer": [
			{"speaker": "ほのか", "text": "うわあ、また大きくなってる！ 夏休みどうだったの？"},
			{"speaker": "ほのか", "text": "バレー部、また続けるの？ 応援してるよ。"},
		],
	},
	"senior": {
		"first_meet": [
			{"speaker": "バレー部先輩", "text": "君、ちょっといいかな？"},
			{"speaker": "バレー部先輩", "text": "……すごいな、ネットより頭一つ高いじゃないか"},
			{"speaker": "バレー部先輩", "text": "バレー部、興味ない？ 君なら無敵のアタッカーになれるよ。"},
			{"speaker": "バレー部先輩", "text": "もし気が向いたら、体育館に顔を出してみてくれ。"},
		],
		"huge": [
			{"speaker": "バレー部先輩", "text": "（驚きながら）……また大きくなったか？"},
			{"speaker": "バレー部先輩", "text": "体育館の入り口、頭ぶつけないように気をつけろよ。"},
		],
		"join_invite": [
			{"speaker": "バレー部先輩", "text": "体育館に来てくれたか。改めて、入部どうだ？"},
			{
				"speaker": "バレー部先輩",
				"text": "身長も才能のうちだ。一緒にやってみないか？",
				"choices": [
					{"label": "入部する！", "next": "join_accepted", "action": "vball_join"},
					{"label": "もう少し考えたい……", "next": "join_think"},
					{"label": "やっぱりやめておく", "next": "join_decline"},
				]
			},
		],
		"join_accepted": [
			{"speaker": "バレー部先輩", "text": "よし！ ようこそバレー部へ。"},
			{"speaker": "バレー部先輩", "text": "まず基本から教えるよ。一緒に頑張ろう。"},
		],
		"join_think": [
			{"speaker": "バレー部先輩", "text": "そうか。また来たときに声をかけてくれ。"},
		],
		"join_decline": [
			{"speaker": "バレー部先輩", "text": "残念だけど、気が変わったらいつでも来い。"},
		],
		"practice_first": [
			{"speaker": "バレー部先輩", "text": "最近の練習、だいぶ慣れてきたな。"},
			{"speaker": "バレー部先輩", "text": "……でも、右脚、大丈夫か？ 少しかばってるように見えるけど。"},
		],
		"pain_concern": [
			{"speaker": "バレー部先輩", "text": "ほのかから聞いたよ。脚が痛いんだって？"},
			{"speaker": "バレー部先輩", "text": "今は無理するな。しばらく休部して、ちゃんと診てもらえ。"},
			{"speaker": "バレー部先輩", "text": "治ったらいつでも戻ってこい。待ってるから。"},
		],
		"senior_after_summer": [
			{"speaker": "バレー部先輩", "text": "おい……夏休みの間にまた大きくなったか！"},
			{"speaker": "バレー部先輩", "text": "脚の具合はどうだ？ 続けられそうか？"},
			{
				"speaker": "バレー部先輩",
				"text": "正直に教えてくれ。",
				"choices": [
					{"label": "また頑張りたい！", "next": "vball_return", "action": "vball_rejoin"},
					{"label": "マネージャーとして関わりたい", "next": "vball_manager", "action": "vball_manager_role"},
					{"label": "今は勉強に集中したい……", "next": "vball_retire"},
				]
			},
		],
		"vball_return": [
			{"speaker": "バレー部先輩", "text": "よし！ 待ってたぞ。今学期も一緒に頑張ろう。"},
		],
		"vball_manager": [
			{"speaker": "バレー部先輩", "text": "マネージャーか。それも大切な役割だよ。よろしく。"},
		],
		"vball_retire": [
			{"speaker": "バレー部先輩", "text": "そうか……ゆっくり考えてくれ。応援してるよ。"},
		],
	},
	"mother": {
		"first_meet": [
			{"speaker": "お母さん", "text": "おかえり。ご飯もうすぐできるよ。"},
			{"speaker": "お母さん", "text": "立って？ ……また背、伸びたんじゃない？"},
		],
		"check": [
			{"speaker": "お母さん", "text": "あら、また制服の丈が短くなったわね。"},
			{"speaker": "お母さん", "text": "もうミニスカートどころじゃないわよ。"},
			{"speaker": "お母さん", "text": "夏休みの間に何があったの？ 急成長しすぎじゃない？"},
		],
	},
	"father": {
		"first_meet": [
			{"speaker": "お父さん", "text": "おかえり。"},
			{"speaker": "お父さん", "text": "……背、伸びたな。"},
		],
		"check": [
			{"speaker": "お父さん", "text": "……。"},
			{"speaker": "お父さん", "text": "いつの間にか、お父さんより頭二つ分も大きいんだな。"},
			{"speaker": "お父さん", "text": "天井の電球、替えてくれるかい？"},
		],
	},
	"teacher": {
		"semester_start": [
			{"speaker": "田中先生", "text": "起立、礼。着席。"},
			{"speaker": "田中先生", "text": "新学期が始まりましたね。今学期もよろしく。"},
			{"speaker": "田中先生", "text": "……あなた、また背が伸びたんですか。後ろの席に座ってください"},
		],
	},
	"nurse": {
		"default": [
			{"speaker": "保健の先生", "text": "あら、今日も身長を測りに来たの？"},
			{"speaker": "保健の先生", "text": "身長計の前に立って。はい、背筋をまっすぐ。"},
		],
	},
	"player": {
		"summer_growth": [
			{"speaker": "（主人公）", "text": "……制服のボタン、止まらない。"},
			{"speaker": "（主人公）", "text": "夏休みの間に、こんなに伸びてたの？"},
			{"speaker": "お母さん", "text": "ちょっと待って、また背が伸びた？"},
			{"speaker": "お母さん", "text": "夏休みだけで10センチ？ そんなことある？"},
			{"speaker": "お母さん", "text": "制服、買い直しね。もう丈が全然足りないわ。"},
		],
		"new_semester": [
			{"speaker": "（主人公）", "text": "新学期か……。"},
			{"speaker": "（主人公）", "text": "また少し背が伸びた気がする。今学期も色々あるんだろうな。"},
		],
		"entrance_elementary": [
			{"speaker": "（主人公）", "text": "今日は小学校の入学式だ。"},
			{"speaker": "（主人公）", "text": "ランドセルが重たい……でも、楽しみだな。"},
		],
		"entrance_middle": [
			{"speaker": "（主人公）", "text": "今日は中学校の入学式だ。"},
			{"speaker": "（主人公）", "text": "制服の袖が、もうギリギリだ。"},
		],
		"entrance_high": [
			{"speaker": "（主人公）", "text": "今日は高校の入学式だ。"},
			{"speaker": "（主人公）", "text": "式場に入ったら、また一番後ろに立たされた。"},
		],
		"summer_growth_vball": [
			{"speaker": "（主人公）", "text": "……制服のボタン、全然止まらない。"},
			{"speaker": "（主人公）", "text": "夏休みの間に、こんなに伸びてたの？"},
			{"speaker": "お母さん", "text": "ちょっと待って……夏休みだけで10センチ？"},
			{"speaker": "お母さん", "text": "制服も買い直しだし、バレー部のユニフォームも作り直しね。"},
			{"speaker": "（主人公）", "text": "……来学期、部活に戻れるかな。脚の具合も気になるし。"},
		],
	},
	"generic": {
		"first_meet": [
			{"speaker": "人", "text": "えっ……！？"},
			{"speaker": "人", "text": "（信じられないものを見るように見上げている）"},
		],
		"huge": [
			{"speaker": "人", "text": "うわっ、でかっ……！"},
			{"speaker": "人", "text": "（あまりの大きさに言葉を失っているようだ）"},
		],
		"tall": [
			{"speaker": "人", "text": "おお、背高いな……。"},
			{"speaker": "人", "text": "（首を痛めそうな角度で見上げられている）"},
		],
		"default": [
			{"speaker": "人", "text": "あ、こんにちは。"},
			{"speaker": "人", "text": "（見上げながら挨拶を返してくれた）"},
		]
	},
}
