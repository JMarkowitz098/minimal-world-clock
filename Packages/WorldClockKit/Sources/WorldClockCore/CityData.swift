/// The bundled `CityTable`: about a thousand cities that don't name a zone, so search finds
/// "San Francisco" (Los Angeles) or "Osaka" (Tokyo). Written by hand from public facts (which
/// zone a city keeps time in); not taken from a dataset. `*` marks a major metro or capital,
/// which ranks first; a `*` before the identifier marks the zone's own city as major.
/// Format: `CityTable.init(parsing:)`. `everyCityPointsToAKnownZone` checks every line.
/// The system lists some zones only by older names (Asia/Calcutta, Asia/Saigon is missing but
/// Asia/Ho_Chi_Minh is there), so a city's today's name may be an alias here (Kolkata).
enum CityData {
    /// Other names for countries, by ISO 3166 code: what people type that the system's English
    /// country name ("United Kingdom", "Türkiye", "Czechia") doesn't contain.
    static let countryNames: [String: [String]] = [
        "US": ["USA", "US", "United States of America"],
        "GB": ["UK", "Britain", "Great Britain", "England", "Scotland", "Wales", "Northern Ireland"],
        "AE": ["UAE", "Emirates"],
        "NL": ["Holland"],
        "CZ": ["Czech Republic"],
        "TR": ["Turkey"],
        "MM": ["Burma"],
        "CI": ["Ivory Coast"],
        "CD": ["DRC", "Congo"],
        "CG": ["Congo"],
        "KR": ["Korea"],
        "SZ": ["Swaziland"],
        "MK": ["Macedonia"],
        "VA": ["Vatican City"],
        "PS": ["Palestine"],
        "HK": ["Hong Kong"],
        "MO": ["Macau"],
        "CV": ["Cape Verde"],
        "TL": ["East Timor"],
        "FM": ["Micronesia"],
        "RU": ["Russian Federation"],
    ]

    static let table = """
    // North America: United States
    *America/New_York: *NYC, *Boston, *Philadelphia, *Washington, *Washington DC, *Atlanta, *Miami, Baltimore, Pittsburgh, Charlotte, Raleigh, Orlando, Tampa, Jacksonville, Columbus, Cleveland, Cincinnati, Buffalo, Rochester, Albany, Syracuse, Newark, Jersey City, Hartford, New Haven, Providence, Portland, Burlington, Richmond, Virginia Beach, Norfolk, Arlington, Durham, Greensboro, Charleston, Columbia, Savannah, Fort Lauderdale, West Palm Beach, St. Petersburg, Tallahassee, Gainesville, Key West, Lexington, Wilmington, Annapolis, Brooklyn, Queens, Manhattan, The Bronx, Long Island, Princeton, Atlantic City, Scranton, Harrisburg, Allentown, Akron, Dayton, Toledo, Knoxville, Chattanooga, Asheville, Myrtle Beach, Augusta, Cambridge, Worcester, Springfield, Manchester, Concord, Montpelier, Trenton, Dover
    America/Detroit: Ann Arbor, Grand Rapids, Lansing, Flint, Kalamazoo, Dearborn, Traverse City
    America/Indiana/Indianapolis: Fort Wayne, Bloomington, South Bend, Evansville, Carmel
    America/Kentucky/Louisville: Frankfort
    *America/Chicago: *Houston, *Dallas, *San Antonio, *Austin, Fort Worth, Milwaukee, Minneapolis, St. Paul, Saint Paul, Kansas City, St. Louis, Saint Louis, Memphis, Nashville, New Orleans, Oklahoma City, Tulsa, Omaha, Des Moines, Madison, Green Bay, Little Rock, Birmingham, Montgomery, Mobile, Huntsville, Jackson, Baton Rouge, Shreveport, Lafayette, Corpus Christi, Laredo, Lubbock, Amarillo, Waco, Plano, Arlington, Galveston, Brownsville, McAllen, Wichita, Topeka, Lincoln, Sioux Falls, Fargo, Bismarck, Springfield, Peoria, Rockford, Naperville, Evanston, Duluth, Rochester, Cedar Rapids, Iowa City, Davenport, Pensacola, Branson, Jefferson City, Fayetteville, Bentonville, Biloxi
    *America/Denver: Salt Lake City, Albuquerque, Colorado Springs, Boulder, Aurora, Fort Collins, Santa Fe, Las Cruces, El Paso, Cheyenne, Casper, Billings, Missoula, Bozeman, Helena, Provo, Ogden, Park City, Aspen, Vail, Durango, Jackson Hole
    America/Boise: Idaho Falls, Pocatello, Twin Falls, Nampa
    America/Phoenix: Tucson, Mesa, Scottsdale, Chandler, Tempe, Glendale, Flagstaff, Sedona, Yuma, Gilbert, Peoria
    *America/Los_Angeles: *LA, *San Francisco, *SF, *San Diego, *San Jose, *Seattle, *Las Vegas, *Silicon Valley, Portland, Sacramento, Oakland, Fresno, Long Beach, Bakersfield, Anaheim, Santa Ana, Irvine, Riverside, San Bernardino, Stockton, Modesto, Palo Alto, Mountain View, Sunnyvale, Cupertino, Menlo Park, Berkeley, Santa Clara, Santa Monica, Pasadena, Burbank, Glendale, Hollywood, Beverly Hills, Malibu, Palm Springs, Santa Barbara, Santa Cruz, Monterey, Napa, Sonoma, Lake Tahoe, Reno, Carson City, Henderson, Spokane, Tacoma, Bellevue, Redmond, Olympia, Everett, Vancouver, Eugene, Salem, Bend, Medford, Chula Vista, Oceanside, Ventura, Oxnard, Santa Rosa, Eureka, Redding, San Luis Obispo
    America/Anchorage: Fairbanks, Wasilla, Kenai, Palmer
    America/Juneau: Ketchikan
    America/Sitka:
    America/Nome:
    *Pacific/Honolulu: Hawaii, Hilo, Maui, Kahului, Lahaina, Kailua, Kona, Waikiki, Lihue, Kauai, Oahu, Pearl City
    America/Puerto_Rico: *San Juan, Ponce, Bayamón, Mayagüez, Caguas
    Pacific/Guam: Hagåtña, Tamuning
    Pacific/Pago_Pago:
    America/St_Thomas: Charlotte Amalie, St. Croix
    // Canada
    *America/Toronto: *Ottawa, Mississauga, Brampton, Hamilton, London, Markham, Vaughan, Kitchener, Waterloo, Windsor, Oshawa, Barrie, Kingston, Guelph, Sudbury, Niagara Falls, Quebec City, Québec, Laval, Gatineau, Longueuil, Sherbrooke, Trois-Rivières, Saguenay, Thunder Bay
    *America/Vancouver: Victoria, Surrey, Burnaby, Richmond, Kelowna, Abbotsford, Coquitlam, Nanaimo, Kamloops, Whistler, Prince George
    America/Edmonton: *Calgary, Red Deer, Lethbridge, Banff, Fort McMurray, Medicine Hat
    America/Winnipeg: Brandon, Kenora
    America/Regina: Saskatoon, Prince Albert, Moose Jaw
    America/Halifax: Charlottetown, Sydney, Dartmouth, Truro
    America/Moncton: Saint John, Fredericton
    America/St_Johns: St. John's, Newfoundland, Corner Brook, Gander
    America/Whitehorse: Dawson City
    America/Yellowknife:
    America/Iqaluit:
    // Mexico, Central America and the Caribbean
    *America/Mexico_City: *Guadalajara, *Puebla, Ciudad de México, CDMX, León, Querétaro, Toluca, Aguascalientes, Morelia, San Luis Potosí, Veracruz, Acapulco, Oaxaca, Cuernavaca, Pachuca, Tuxtla Gutiérrez, Villahermosa, Xalapa, Zacatecas, Guanajuato, San Miguel de Allende, Puerto Escondido, Durango, Torreón, Campeche
    America/Monterrey: *Saltillo, San Pedro Garza García
    America/Matamoros: Reynosa, Nuevo Laredo
    America/Cancun: Playa del Carmen, Tulum, Cozumel, Chetumal
    America/Merida: Progreso
    America/Tijuana: Mexicali, Ensenada, Rosarito
    America/Ciudad_Juarez: Juárez
    America/Chihuahua: Delicias
    America/Hermosillo: Sonora, Ciudad Obregón, Nogales, Guaymas
    America/Mazatlan: Culiacán, La Paz, Los Cabos, Cabo San Lucas, San José del Cabo, Tepic
    America/Bahia_Banderas: Puerto Vallarta, Nuevo Vallarta
    America/Guatemala: Guatemala City, Quetzaltenango, Antigua
    America/Belize: Belize City, Belmopan
    America/El_Salvador: San Salvador, Santa Ana
    America/Tegucigalpa: San Pedro Sula, Roatán
    America/Managua: León, Granada
    America/Costa_Rica: San José, Liberia, Limón
    America/Panama: Panama City, Colón
    America/Havana: Santiago de Cuba, Varadero, Camagüey, Holguín
    America/Jamaica: Kingston, Montego Bay, Ocho Rios, Negril
    America/Port-au-Prince: Cap-Haïtien, Pétion-Ville
    America/Santo_Domingo: Santiago de los Caballeros, Punta Cana, Puerto Plata, La Romana
    America/Nassau: Freeport
    America/Barbados: Bridgetown
    America/Port_of_Spain: San Fernando, Chaguanas
    America/Curacao: Willemstad
    America/Aruba: Oranjestad
    America/Martinique: Fort-de-France
    America/Guadeloupe: Pointe-à-Pitre, Basse-Terre
    America/St_Lucia: Castries
    America/Grenada: St. George's
    America/St_Vincent: Kingstown
    America/Antigua: St. John's
    America/St_Kitts: Basseterre
    America/Dominica: Roseau
    America/Cayman: George Town
    America/Grand_Turk: Providenciales, Turks and Caicos
    America/Tortola: Road Town
    America/Anguilla: The Valley
    America/St_Barthelemy: Gustavia
    America/Marigot: Saint Martin
    America/Lower_Princes: Philipsburg
    America/Kralendijk: Bonaire
    America/Montserrat: Plymouth
    Atlantic/Bermuda: Hamilton
    // South America
    *America/Sao_Paulo: *Rio de Janeiro, *Brasília, *Belo Horizonte, *Curitiba, *Porto Alegre, Campinas, Goiânia, Florianópolis, Santos, Niterói, Guarulhos, São José dos Campos, Ribeirão Preto, Sorocaba, Uberlândia, Londrina, Joinville, Vitória, Juiz de Fora, Petrópolis, Búzios, Paraty, Foz do Iguaçu
    America/Bahia: *Salvador, Feira de Santana, Ilhéus, Porto Seguro
    America/Recife: Olinda, Jaboatão, Caruaru
    America/Fortaleza: Natal, João Pessoa, São Luís, Teresina, Jericoacoara
    America/Maceio: Aracaju
    America/Belem: Macapá, Santarém
    America/Manaus: Boa Vista
    America/Cuiaba: Várzea Grande
    America/Campo_Grande: Dourados
    America/Porto_Velho:
    America/Rio_Branco:
    America/Noronha: Fernando de Noronha
    *America/Argentina/Buenos_Aires: La Plata, Mar del Plata, Bahía Blanca, Quilmes
    America/Argentina/Cordoba: Rosario, Santa Fe, Paraná, Corrientes, Resistencia, Posadas
    America/Argentina/Mendoza: San Rafael
    America/Argentina/Salta: Neuquén
    America/Argentina/Ushuaia: Tierra del Fuego
    America/Argentina/Rio_Gallegos: El Calafate
    America/Argentina/Tucuman: San Miguel de Tucumán
    America/Argentina/Catamarca: Comodoro Rivadavia, Trelew
    America/Argentina/San_Luis:
    America/Argentina/Jujuy:
    *America/Santiago: Valparaíso, Viña del Mar, Concepción, Antofagasta, Temuco, La Serena, Iquique, Arica, Puerto Montt, Rancagua, Talca
    America/Punta_Arenas: Puerto Natales
    Pacific/Easter: Easter Island, Rapa Nui, Hanga Roa
    *America/Bogota: *Medellín, Cali, Barranquilla, Cartagena, Bucaramanga, Santa Marta, Pereira, Manizales, Cúcuta, Ibagué
    *America/Lima: Arequipa, Cusco, Cuzco, Trujillo, Chiclayo, Iquitos, Piura, Huancayo, Puno, Machu Picchu
    America/Guayaquil: *Quito, Cuenca, Manta
    Pacific/Galapagos: Puerto Ayora
    *America/Caracas: Maracaibo, Valencia, Barquisimeto, Maracay, Ciudad Guayana, Mérida
    America/La_Paz: Santa Cruz de la Sierra, Cochabamba, Sucre, El Alto, Oruro, Potosí
    America/Asuncion: Ciudad del Este, Encarnación
    America/Montevideo: Punta del Este, Salto, Colonia del Sacramento
    America/Guyana: Georgetown
    America/Paramaribo:
    America/Cayenne: Kourou
    Atlantic/Stanley: Port Stanley
    Atlantic/South_Georgia:
    // Europe
    *Europe/London: *Manchester, *Birmingham, *Edinburgh, Glasgow, Liverpool, Leeds, Bristol, Sheffield, Newcastle, Cardiff, Belfast, Nottingham, Leicester, Southampton, Brighton, Oxford, Cambridge, Aberdeen, York, Coventry, Reading, Portsmouth, Swansea, Plymouth, Bath, Bradford, Hull, Stoke-on-Trent, Wolverhampton, Derby, Dundee, Inverness, Exeter, Norwich, Canterbury, Milton Keynes, Bournemouth, Sunderland, Middlesbrough, Preston, Luton, Stratford-upon-Avon, Windsor, Heathrow, Gatwick
    Europe/Guernsey: St Peter Port
    Europe/Jersey: St Helier
    Europe/Isle_of_Man: Douglas
    *Europe/Dublin: Cork, Galway, Limerick, Waterford, Kilkenny, Killarney
    *Europe/Lisbon: *Porto, Braga, Coimbra, Faro, Albufeira, Lagos, Sintra, Cascais, Aveiro, Évora
    Atlantic/Madeira: Funchal
    Atlantic/Azores: Ponta Delgada
    Atlantic/Canary: Las Palmas, Tenerife, Santa Cruz de Tenerife, Gran Canaria, Lanzarote, Fuerteventura
    *Europe/Madrid: *Barcelona, Valencia, Seville, Sevilla, Zaragoza, Málaga, Bilbao, Palma, Palma de Mallorca, Mallorca, Alicante, Granada, Murcia, Ibiza, Valladolid, Córdoba, San Sebastián, Santiago de Compostela, Salamanca, Toledo, Cádiz, Marbella, Benidorm, Pamplona, Vigo, A Coruña, Gijón, Oviedo, Santander, Menorca, Girona, Tarragona
    *Europe/Paris: *Marseille, *Lyon, Toulouse, Nice, Nantes, Strasbourg, Montpellier, Bordeaux, Lille, Rennes, Reims, Grenoble, Dijon, Cannes, Avignon, Toulon, Le Havre, Saint-Étienne, Angers, Nîmes, Aix-en-Provence, Tours, Clermont-Ferrand, Limoges, Metz, Nancy, Caen, Rouen, Orléans, Mulhouse, Perpignan, Biarritz, Annecy, Chamonix, Versailles, Ajaccio, Corsica, Saint-Tropez, Antibes
    Europe/Monaco: Monte Carlo
    *Europe/Brussels: Antwerp, Ghent, Bruges, Liège, Charleroi, Leuven, Namur, Mons, Ostend
    *Europe/Amsterdam: Rotterdam, The Hague, Den Haag, Utrecht, Eindhoven, Groningen, Tilburg, Haarlem, Leiden, Delft, Maastricht, Nijmegen, Arnhem, Breda, Schiphol
    Europe/Luxembourg: Esch-sur-Alzette
    *Europe/Berlin: *Hamburg, *Munich, München, *Frankfurt, *Cologne, Köln, Stuttgart, Düsseldorf, Dortmund, Essen, Leipzig, Bremen, Dresden, Hanover, Hannover, Nuremberg, Nürnberg, Duisburg, Bochum, Wuppertal, Bielefeld, Bonn, Münster, Mannheim, Karlsruhe, Augsburg, Wiesbaden, Heidelberg, Freiburg, Kiel, Rostock, Mainz, Aachen, Potsdam, Regensburg, Würzburg, Erfurt, Magdeburg, Lübeck, Saarbrücken, Ulm, Göttingen, Ingolstadt, Wolfsburg, Darmstadt, Weimar, Garmisch-Partenkirchen, Berchtesgaden
    Europe/Zurich: *Geneva, Genève, Basel, Bern, Lausanne, Lucerne, Luzern, Lugano, St. Gallen, Winterthur, Zermatt, Interlaken, Davos, St. Moritz
    Europe/Vaduz:
    *Europe/Vienna: Wien, Graz, Linz, Salzburg, Innsbruck, Klagenfurt, Villach, Hallstatt
    *Europe/Rome: *Milan, Milano, *Naples, Napoli, Turin, Torino, Palermo, Genoa, Genova, Bologna, Florence, Firenze, Venice, Venezia, Verona, Bari, Catania, Messina, Trieste, Padua, Padova, Pisa, Siena, Como, Lake Como, Sorrento, Amalfi, Positano, Capri, Cagliari, Sardinia, Sicily, Perugia, Parma, Modena, Brescia, Bergamo, Rimini, Lecce, Taormina, Cinque Terre
    Europe/Vatican: Holy See
    Europe/San_Marino:
    Europe/Malta: Valletta, Sliema, Gozo
    *Europe/Prague: Praha, Brno, Ostrava, Plzeň, Pilsen, Karlovy Vary, Český Krumlov, Olomouc
    Europe/Bratislava: Košice, Žilina
    *Europe/Warsaw: *Kraków, Łódź, Wrocław, Poznań, Gdańsk, Szczecin, Lublin, Katowice, Gdynia, Bydgoszcz, Białystok, Toruń, Zakopane, Sopot
    *Europe/Budapest: Debrecen, Szeged, Pécs, Győr, Miskolc
    Europe/Ljubljana: Maribor, Bled, Piran
    Europe/Zagreb: Split, Dubrovnik, Rijeka, Zadar, Pula, Osijek, Hvar
    Europe/Sarajevo: Mostar, Banja Luka, Tuzla
    Europe/Belgrade: Novi Sad, Niš, Kragujevac, Pristina, Prishtina, Kosovo
    Europe/Podgorica: Kotor, Budva, Herceg Novi
    Europe/Skopje: Ohrid, Bitola
    Europe/Tirane: Tirana, Durrës, Vlorë, Shkodër, Sarandë
    *Europe/Athens: Thessaloniki, Patras, Heraklion, Crete, Rhodes, Mykonos, Santorini, Corfu, Piraeus, Larissa, Chania, Kos, Zakynthos, Volos, Ioannina
    Europe/Sofia: Plovdiv, Varna, Burgas, Ruse, Bansko
    *Europe/Bucharest: Cluj-Napoca, Timișoara, Iași, Constanța, Brașov, Sibiu, Craiova, Oradea, Galați
    Europe/Chisinau: Bălți, Tiraspol
    *Europe/Kyiv: *Kiev, Kharkiv, Odesa, Odessa, Dnipro, Lviv, Zaporizhzhia, Vinnytsia, Mykolaiv, Chernihiv, Poltava, Ivano-Frankivsk, Uzhhorod, Chernivtsi
    Europe/Simferopol: Sevastopol, Yalta, Crimea
    Europe/Minsk: Gomel, Homyel, Grodno, Vitebsk, Mogilev, Brest
    Europe/Vilnius: Kaunas, Klaipėda
    Europe/Riga: Daugavpils, Jūrmala
    Europe/Tallinn: Tartu, Pärnu
    *Europe/Helsinki: Espoo, Tampere, Vantaa, Turku, Oulu, Rovaniemi, Lapland, Jyväskylä, Lahti
    Europe/Mariehamn:
    *Europe/Stockholm: *Gothenburg, Göteborg, Malmö, Uppsala, Västerås, Örebro, Linköping, Helsingborg, Kiruna, Norrköping, Lund, Umeå, Visby
    *Europe/Oslo: Bergen, Trondheim, Stavanger, Tromsø, Drammen, Kristiansand, Ålesund, Bodø, Lofoten
    Arctic/Longyearbyen:
    *Europe/Copenhagen: Aarhus, Odense, Aalborg, Esbjerg, Roskilde
    Atlantic/Faroe: Tórshavn
    Atlantic/Reykjavik: Akureyri, Keflavík
    America/Nuuk: Godthåb
    Europe/Gibraltar:
    Europe/Andorra: Andorra la Vella
    *Europe/Istanbul: *Ankara, Izmir, Bursa, Antalya, Adana, Konya, Gaziantep, Kayseri, Mersin, Trabzon, Bodrum, Eskişehir, Diyarbakır, Samsun, Denizli, Fethiye, Marmaris, Cappadocia, Göreme, Kuşadası, Dalaman, Alanya
    Asia/Nicosia: Limassol, Larnaca, Paphos
    Asia/Famagusta: Kyrenia
    // Russia and the former Soviet Union
    *Europe/Moscow: *Saint Petersburg, *St. Petersburg, Nizhny Novgorod, Kazan, Rostov-on-Don, Voronezh, Krasnodar, Sochi, Yaroslavl, Tula, Ryazan, Tver, Vladimir, Ivanovo, Bryansk, Kursk, Belgorod, Lipetsk, Smolensk, Kaluga, Murmansk, Arkhangelsk, Petrozavodsk, Veliky Novgorod, Pskov, Cheboksary, Penza, Stavropol, Makhachkala, Grozny, Vladikavkaz, Nalchik, Novorossiysk
    Europe/Kaliningrad: Königsberg
    Europe/Samara: Tolyatti, Togliatti, Izhevsk
    Europe/Volgograd: Stalingrad
    Europe/Saratov: Engels
    Europe/Ulyanovsk:
    Europe/Astrakhan:
    Europe/Kirov:
    Asia/Yekaterinburg: *Chelyabinsk, Perm, Ufa, Tyumen, Orenburg, Magnitogorsk, Surgut, Kurgan
    Asia/Omsk:
    Asia/Novosibirsk: Akademgorodok
    Asia/Barnaul: Altai
    Asia/Tomsk:
    Asia/Novokuznetsk: Kemerovo
    Asia/Krasnoyarsk: Norilsk, Abakan, Kyzyl
    Asia/Irkutsk: Ulan-Ude, Bratsk, Lake Baikal
    Asia/Chita:
    Asia/Yakutsk: Blagoveshchensk
    Asia/Vladivostok: Khabarovsk, Nakhodka, Komsomolsk-on-Amur
    Asia/Sakhalin: Yuzhno-Sakhalinsk
    Asia/Magadan:
    Asia/Kamchatka: Petropavlovsk-Kamchatsky
    Asia/Anadyr:
    Asia/Tbilisi: Batumi, Kutaisi, Rustavi
    Asia/Yerevan: Gyumri, Vanadzor
    Asia/Baku: Ganja, Sumqayit
    *Asia/Almaty: *Astana, Nur-Sultan, Shymkent, Karaganda, Taraz, Pavlodar, Ust-Kamenogorsk, Semey
    Asia/Aqtobe: Aktobe
    Asia/Aqtau: Aktau
    Asia/Atyrau:
    Asia/Oral: Uralsk
    Asia/Qyzylorda: Kyzylorda
    Asia/Qostanay: Kostanay
    *Asia/Tashkent: Namangan, Andijan, Fergana
    Asia/Samarkand: Bukhara, Nukus, Khiva
    Asia/Bishkek: Osh
    Asia/Dushanbe: Khujand
    Asia/Ashgabat: Turkmenabat, Mary
    // Middle East
    *Asia/Dubai: *Abu Dhabi, Sharjah, Al Ain, Ajman, Ras Al Khaimah, Fujairah
    Asia/Muscat: Salalah, Sohar
    *Asia/Riyadh: *Jeddah, Mecca, Makkah, Medina, Dammam, Khobar, Taif, Tabuk, Abha, Al Khobar, Dhahran
    Asia/Qatar: *Doha
    Asia/Bahrain: Manama
    Asia/Kuwait: Kuwait City
    *Asia/Tehran: Isfahan, Mashhad, Shiraz, Tabriz, Karaj, Qom, Ahvaz, Kermanshah, Yazd, Kish
    *Asia/Baghdad: Basra, Mosul, Erbil, Najaf, Karbala, Sulaymaniyah, Kirkuk
    *Asia/Jerusalem: *Tel Aviv, Haifa, Eilat, Beersheba, Be'er Sheva, Netanya, Rishon LeZion, Ashdod, Herzliya, Nazareth
    Asia/Hebron: Ramallah, Bethlehem, Nablus, Jericho, West Bank
    Asia/Gaza: Gaza City, Khan Yunis, Rafah
    Asia/Amman: Zarqa, Irbid, Aqaba, Petra
    Asia/Beirut: Byblos, Sidon, Tyre, Baalbek
    Asia/Damascus: Aleppo, Homs, Latakia, Hama
    Asia/Aden: Sanaa, Sana'a, Taiz, Hodeidah
    // South Asia
    *Asia/Calcutta: *Mumbai, *Delhi, *New Delhi, *Bangalore, *Bengaluru, *Hyderabad, *Chennai, *Kolkata, *Pune, *Ahmedabad, Bombay, Madras, Surat, Jaipur, Lucknow, Kanpur, Nagpur, Indore, Bhopal, Patna, Vadodara, Ludhiana, Agra, Nashik, Varanasi, Amritsar, Chandigarh, Coimbatore, Kochi, Cochin, Thiruvananthapuram, Trivandrum, Goa, Panaji, Visakhapatnam, Vijayawada, Guwahati, Bhubaneswar, Mysore, Mysuru, Madurai, Srinagar, Dehradun, Gurgaon, Gurugram, Noida, Ranchi, Raipur, Jodhpur, Udaipur, Mangalore, Rajkot, Meerut, Allahabad, Prayagraj, Shimla, Rishikesh, Pondicherry, Puducherry, Tiruchirappalli, Kozhikode, Jammu, Leh, Darjeeling, Shillong, Imphal, Aurangabad, Jabalpur, Gwalior, Thane, Navi Mumbai
    *Asia/Karachi: *Lahore, *Islamabad, Rawalpindi, Faisalabad, Multan, Peshawar, Quetta, Hyderabad, Sialkot, Gujranwala, Sukkur, Abbottabad
    *Asia/Dhaka: Chittagong, Chattogram, Khulna, Sylhet, Rajshahi, Cox's Bazar
    Asia/Kathmandu: Pokhara, Lalitpur, Bhaktapur, Everest
    Asia/Thimphu: Paro
    Asia/Colombo: Kandy, Galle, Jaffna, Negombo, Sri Jayawardenepura Kotte
    Indian/Maldives: Malé
    Asia/Kabul: Kandahar, Herat, Mazar-i-Sharif, Jalalabad
    // East Asia
    *Asia/Shanghai: *Beijing, *Shenzhen, *Guangzhou, *Chengdu, *Tianjin, *Wuhan, *Xi'an, *Hangzhou, *Nanjing, Shenyang, Dalian, Qingdao, Suzhou, Zhengzhou, Changsha, Kunming, Jinan, Xiamen, Fuzhou, Hefei, Nanning, Shijiazhuang, Taiyuan, Lanzhou, Changchun, Ningbo, Dongguan, Foshan, Wuxi, Guiyang, Nanchang, Hohhot, Lhasa, Sanya, Haikou, Zhuhai, Peking, Canton, Xining, Yinchuan, Guilin, Lijiang, Datong, Luoyang, Yantai, Weihai, Wenzhou, Shantou, Tibet, Hainan
    Asia/Urumqi: Kashi, Xinjiang
    Asia/Hong_Kong: Kowloon, Victoria Harbour, Tsim Sha Tsui
    Asia/Macau: Macao
    *Asia/Taipei: Kaohsiung, Taichung, Tainan, Taoyuan, Hsinchu, Keelung, Hualien
    *Asia/Tokyo: *Osaka, *Yokohama, *Nagoya, Sapporo, Fukuoka, Kobe, Kyoto, Kawasaki, Saitama, Hiroshima, Sendai, Chiba, Kitakyushu, Naha, Okinawa, Nara, Kanazawa, Niigata, Kumamoto, Kagoshima, Hamamatsu, Shizuoka, Okayama, Matsuyama, Nagasaki, Hakodate, Nikko, Hakone, Kamakura, Takayama, Narita, Shinjuku, Shibuya
    *Asia/Seoul: *Busan, Incheon, Daegu, Daejeon, Gwangju, Ulsan, Suwon, Jeju, Changwon, Seongnam, Goyang, Pusan
    Asia/Pyongyang: Kaesong, Hamhung
    Asia/Ulaanbaatar: Ulan Bator, Darkhan, Erdenet
    Asia/Hovd:
    // Southeast Asia
    *Asia/Bangkok: Chiang Mai, Phuket, Pattaya, Krabi, Hat Yai, Koh Samui, Chiang Rai, Hua Hin, Ayutthaya, Nakhon Ratchasima, Khon Kaen, Udon Thani
    *Asia/Ho_Chi_Minh: *Saigon, *Hanoi, Ho Chi Minh City, Da Nang, Haiphong, Hai Phong, Hue, Nha Trang, Can Tho, Hoi An, Ha Long, Da Lat, Vung Tau, Phu Quoc
    Asia/Phnom_Penh: Siem Reap, Sihanoukville, Battambang
    Asia/Vientiane: Luang Prabang, Vang Vieng, Pakse
    Asia/Yangon: Mandalay, Naypyidaw, Naypyitaw, Bagan
    *Asia/Kuala_Lumpur: George Town, Penang, Johor Bahru, Ipoh, Malacca, Melaka, Shah Alam, Petaling Jaya, Putrajaya, Langkawi, Cyberjaya
    Asia/Kuching: Kota Kinabalu, Sabah, Sarawak, Miri, Sandakan, Borneo
    *Asia/Singapore: Sentosa
    Asia/Brunei: Bandar Seri Begawan
    *Asia/Jakarta: *Surabaya, *Bandung, Semarang, Yogyakarta, Medan, Palembang, Bogor, Bekasi, Tangerang, Depok, Malang, Padang, Pekanbaru, Solo, Surakarta, Batam, Banda Aceh, Jambi, Lampung, Cirebon, Java, Sumatra
    Asia/Pontianak: Palangkaraya
    Asia/Makassar: *Bali, Denpasar, Ubud, Kuta, Balikpapan, Banjarmasin, Manado, Lombok, Mataram, Samarinda, Kupang, Palu, Sulawesi, Labuan Bajo, Komodo
    Asia/Jayapura: Ambon, Sorong, Papua, Merauke, Ternate
    Asia/Dili:
    *Asia/Manila: *Quezon City, Cebu, Cebu City, Davao, Makati, Taguig, Pasig, Zamboanga, Cagayan de Oro, Baguio, Iloilo, Boracay, Palawan, Puerto Princesa, Bohol, Angeles, Bacolod, Mandaluyong, Paranaque, Las Piñas
    // Africa
    *Africa/Cairo: *Alexandria, Giza, Luxor, Aswan, Sharm el-Sheikh, Hurghada, Port Said, Suez, Ismailia, Mansoura, Tanta, Dahab, El Gouna, Marsa Alam
    *Africa/Casablanca: Rabat, Marrakesh, Marrakech, Fez, Fes, Tangier, Agadir, Meknes, Oujda, Essaouira, Chefchaouen, Kenitra, Tetouan
    Africa/El_Aaiun: Laayoune, Dakhla
    Africa/Algiers: Oran, Constantine, Annaba, Blida, Sétif
    Africa/Tunis: Sfax, Sousse, Djerba, Hammamet, Monastir, Kairouan, Bizerte
    Africa/Tripoli: Benghazi, Misrata
    Africa/Khartoum: Omdurman, Port Sudan, Kassala
    Africa/Juba: Wau, Malakal
    *Africa/Addis_Ababa: Dire Dawa, Bahir Dar, Gondar, Mekelle, Hawassa, Lalibela
    Africa/Asmara: Massawa, Keren, Asmera
    Africa/Djibouti: Djibouti City
    Africa/Mogadishu: Hargeisa, Kismayo, Berbera
    *Africa/Nairobi: Mombasa, Kisumu, Nakuru, Eldoret, Malindi, Lamu, Diani
    Africa/Kampala: Entebbe, Gulu, Jinja, Mbarara
    Africa/Kigali: Butare, Gisenyi
    Africa/Bujumbura: Gitega
    Africa/Dar_es_Salaam: Dodoma, Arusha, Zanzibar, Stone Town, Mwanza, Moshi, Kilimanjaro, Mbeya, Tanga, Morogoro
    *Africa/Lagos: *Abuja, *Kano, *Ibadan, Port Harcourt, Benin City, Kaduna, Enugu, Jos, Calabar, Ilorin, Abeokuta, Onitsha, Owerri, Uyo, Warri, Maiduguri, Sokoto, Zaria, Lekki, Ikeja
    *Africa/Accra: Kumasi, Tamale, Takoradi, Sekondi, Cape Coast, Tema
    *Africa/Abidjan: Yamoussoukro, Bouaké, San-Pédro, Grand-Bassam
    Africa/Dakar: Touba, Thiès, Saint-Louis, Ziguinchor
    Africa/Bamako: Timbuktu, Ségou, Mopti, Sikasso
    Africa/Ouagadougou: Bobo-Dioulasso, Koudougou
    Africa/Niamey: Zinder, Maradi, Agadez
    Africa/Conakry: Kankan, Nzérékoré
    Africa/Freetown: Bo, Kenema
    Africa/Monrovia: Gbarnga, Buchanan
    Africa/Lome: Kara, Sokodé
    Africa/Porto-Novo: Cotonou, Parakou, Abomey
    Africa/Douala: Yaoundé, Bamenda, Garoua, Kribi
    Africa/Libreville: Port-Gentil
    Africa/Malabo: Bata
    Africa/Ndjamena: N'Djamena, Moundou
    Africa/Bangui: Berbérati
    Africa/Nouakchott: Nouadhibou
    Africa/Banjul: Serrekunda
    Africa/Bissau: Bafatá
    Atlantic/Cape_Verde: Praia, Mindelo, Sal
    Africa/Sao_Tome:
    *Africa/Kinshasa: Matadi, Kikwit, Mbandaka
    Africa/Lubumbashi: Kisangani, Goma, Bukavu, Mbuji-Mayi, Kananga, Kolwezi, Likasi
    Africa/Brazzaville: Pointe-Noire, Dolisie
    *Africa/Luanda: Huambo, Lobito, Benguela, Lubango, Cabinda
    Africa/Lusaka: Kitwe, Ndola, Livingstone, Kabwe, Chingola
    Africa/Harare: Bulawayo, Victoria Falls, Mutare, Gweru
    Africa/Maputo: Beira, Nampula, Matola, Quelimane, Tete, Pemba
    Africa/Blantyre: Lilongwe, Mzuzu, Zomba
    Africa/Gaborone: Francistown, Maun, Kasane
    Africa/Windhoek: Walvis Bay, Swakopmund, Lüderitz
    *Africa/Johannesburg: *Cape Town, *Durban, *Pretoria, Port Elizabeth, Gqeberha, Bloemfontein, East London, Soweto, Stellenbosch, Polokwane, Nelspruit, Mbombela, Kimberley, Pietermaritzburg, Sandton, Centurion, George, Knysna, Rustenburg, Paarl
    Africa/Maseru:
    Africa/Mbabane: Manzini, Lobamba
    Indian/Antananarivo: Toamasina, Antsirabe, Mahajanga, Nosy Be
    Indian/Mauritius: Port Louis, Curepipe, Grand Baie
    Indian/Reunion: Saint-Denis, Saint-Pierre
    Indian/Mahe: Victoria, Praslin
    Indian/Comoro: Moroni
    Indian/Mayotte: Mamoudzou
    Atlantic/St_Helena: Jamestown
    // Oceania
    *Australia/Sydney: *Canberra, Newcastle, Wollongong, Central Coast, Blue Mountains, Byron Bay, Coffs Harbour, Wagga Wagga, Albury
    *Australia/Melbourne: Geelong, Ballarat, Bendigo, Mornington
    *Australia/Brisbane: *Gold Coast, Sunshine Coast, Cairns, Townsville, Toowoomba, Mackay, Rockhampton, Noosa, Bundaberg
    Australia/Lindeman: Whitsundays, Airlie Beach, Hamilton Island
    *Australia/Adelaide: Mount Gambier, Barossa
    *Australia/Perth: Fremantle, Mandurah, Bunbury, Rottnest Island, Kalgoorlie, Broome
    Australia/Hobart: Launceston, Tasmania, Devonport
    Australia/Darwin: Alice Springs, Uluru, Katherine
    Australia/Broken_Hill:
    Australia/Lord_Howe:
    Australia/Eucla:
    *Pacific/Auckland: *Wellington, Christchurch, Hamilton, Tauranga, Dunedin, Queenstown, Napier, Rotorua, Nelson, Palmerston North, Invercargill, New Plymouth, Whangarei
    Pacific/Chatham: Chatham Islands
    Pacific/Fiji: Suva, Nadi, Lautoka
    Pacific/Port_Moresby: Lae, Mount Hagen
    Pacific/Bougainville: Arawa
    Pacific/Noumea:
    Pacific/Tahiti: Papeete, Bora Bora, Moorea
    Pacific/Marquesas:
    Pacific/Gambier:
    Pacific/Apia:
    Pacific/Tongatapu: Nuku'alofa
    Pacific/Efate: Port Vila
    Pacific/Guadalcanal: Honiara
    Pacific/Tarawa: South Tarawa
    Pacific/Kiritimati:
    Pacific/Majuro:
    Pacific/Palau: Koror
    Pacific/Pohnpei: Palikir
    Pacific/Chuuk: Weno
    Pacific/Saipan:
    Pacific/Rarotonga: Avarua
    Pacific/Niue: Alofi
    Pacific/Funafuti:
    Pacific/Nauru: Yaren
    Pacific/Norfolk: Kingston
    Pacific/Wallis: Mata-Utu
    Pacific/Fakaofo:
    Pacific/Pitcairn: Adamstown
    // Antarctica and elsewhere
    Antarctica/McMurdo: Ross Island
    Antarctica/Casey:
    Indian/Christmas: Flying Fish Cove
    Indian/Cocos: West Island
    Indian/Chagos: Diego Garcia
    """
}
