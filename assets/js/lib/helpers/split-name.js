
module.exports = function splitName (name) {
	var components = name.split(' ');

	if (components.length < 3) {
		return components;
	}

	var first;
	var last;

	// NOTE: this block is to handle "Natalie Di Maria"
	// (which is a pretty unique case)
	var search = components[1].toLowerCase()
	if (search === 'di' || search === 'freire') {
		first = components[0];
		last = components.slice(1).join(' ');
	} else {
		first = components.slice(0, -1).join(' ');
		last = components.slice(-1).join(' ');
	}

	return [first, last]
};
