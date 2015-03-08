var activeCourses = [];
var specialist = {'index300': 0, 'index400': 0, 'categoriesCompleted': 0, 'filledTextboxes300': 0, 
                  'filledTextboxes400': 0, 'filledTextboxesExtra': 0, 'specCount': 0, 
                  'reqs': ['CSC108', 'CSC148', 'CSC165', 'CSC207', 'CSC209', 'CSC236', 'CSC258', 'CSC263', 
                  'Sta1', 'Lin1', 'Calc1', 'CSC369', 'CSC373'], 'textboxes300': 3, 'textboxes400': 3, 
                  'textboxesExtra': 4, 'categories': 17, 'creditCount': 0};
var major = {'index300': 0, 'index400': 0, 'categoriesCompleted': 0, 'filledTextboxes300': 0, 
             'filledTextboxes400': 0, 'filledTextboxesExtra': 0, 'majCount': 0, 'reqs': ['CSC108', 
             'CSC148', 'CSC165', 'CSC207', 'CSC236', 'CSC258', 'CSC263', 'Sta1', 'Calc1'], 'textboxes300': 2, 
             'textboxes400': 1, 'textboxesExtra': 3, 'categories': 13, 'creditCount': 0};
var minor = {'index300': 0, 'index400': 0, 'categoriesCompleted': 0, 'filledTextboxesExtra': 0, 
             'reqs': ['CSC108', 'CSC148', 'CSC165', 'CSC207', 'CSC236'], 'textboxesExtra': 3, 'categories': 6, 
             'creditCount': 0, 'additionalMin200': ['CSC209', 'CSC258', 'CSC263']};


/**
 * Updates POSts when button is clicked.
**/
$('#update').click(function (e) {
    'use strict';

    updateAllCategories();
    updateNavPost();
});


/**
 * Updates all categories to see if they are fulfilled or not.
**/
function updateAllCategories() {
    'use strict';

    resetValues();

    updateActiveCourses();

    fill400s();
    fill300s();
    fillMisc();
    fillExtra();

    updateReqsCategory(specialist, 'spec');
    updateReqsCategory(major, 'maj');
    updateReqsCategory(minor, 'min');

    update300Categories();
    update400Categories();
    updateExtraCategories();
    updateMatCreditCount();

    fillCreditCount();
    checkPostCompleted();
}


/**
 * Resets all values to initial starting values
**/
function resetValues() {
    'use strict';

    activeCourses = [];
    specialist = {'index300': 0, 'index400': 0, 'categoriesCompleted': 0, 'filledTextboxes300': 0, 'filledTextboxes400': 0, 
                  'filledTextboxesExtra': 0, 'specCount': 0, 'reqs': ['CSC108', 'CSC148', 'CSC165', 'CSC207', 'CSC209', 'CSC236',
                  'CSC258', 'CSC263', 'Sta1', 'Lin1', 'Calc1', 'CSC369', 'CSC373'], 'textboxes300': 3, 'textboxes400': 3, 'textboxesExtra': 4,
                  'categories': 17, 'creditCount': 0};
    major = {'index300': 0, 'index400': 0, 'categoriesCompleted': 0, 'filledTextboxes300': 0, 'filledTextboxes400': 0, 
             'filledTextboxesExtra': 0, 'majCount': 0, 'reqs': ['CSC108', 'CSC148', 'CSC165', 'CSC207', 'CSC236',
             'CSC258', 'CSC263', 'Sta1', 'Calc1'], 'textboxes300': 2, 'textboxes400': 1, 'textboxesExtra': 3, 'categories': 13,
             'creditCount': 0};
    minor = {'index300': 0, 'index400': 0, 'categoriesCompleted': 0, 'filledTextboxesExtra': 0, 'reqs': ['CSC108', 'CSC148', 'CSC165', 'CSC207', 'CSC236'], 
             'textboxesExtra': 3, 'categories': 6, 'creditCount': 0, 'additionalMin200': ['CSC209', 'CSC258', 'CSC263']};
}


/**
 * Records a course as clicked. 
 * @param {string} courseCode The course code
**/
function activateCourse(courseCode) {
    'use strict';
    
    var elements = document.getElementsByClassName(courseCode);
    for (var i = 0; i < elements.length; i++) {
        elements[i].style.backgroundColor = '#99ff99';
    }
}


/**
 * Records a course as not clicked. 
 * @param {string} courseCode The course code
**/
function deactivateCourse(courseCode) {
    'use strict';
    
    var elements = document.getElementsByClassName(courseCode);
    for (var i = 0; i < elements.length; i++) {
            elements[i].style.backgroundColor = '#BABABA';
    }
}


/**
 * Records a category as fulfilled or not fulfilled
 * @param {Element} category Element of category
 * @param {string} status Whether it is 'fulfilled' or 'not fulfilled'
**/
function updateCategory(category, status) {
    'use strict';

    if (status === 'fulfilled') {
        category.style.backgroundColor = "#3CB371";
    } else if (status === 'not fulfilled') {
        category.style.backgroundColor = '#ebe8e4';
    }
}


/**
 * Updates Credit Count for each POSt.
 **/
function fillCreditCount() {
    'use strict';

    fillSpecCreditCount();
    fillMajCreditCount();
    fillMinCreditCount();
}



/**
 * Autofills the credit count for specialist
**/
function fillSpecCreditCount() {
    'use strict';

    if (specialist.creditCount >= 12) {
        $('#spec_creds').html('(12.0/12.0)');
    } else {
        $('#spec_creds').html('(' + specialist.creditCount.toFixed(1) + '/12.0)');
    }
}


/**
 * Autofills the credit count for major
**/
function fillMajCreditCount() {
    'use strict';

    if (major.creditCount >= 8) {
        $('#maj_creds').html('(8.0/8.0)');
    } else {
        $('#maj_creds').html('(' + major.creditCount.toFixed(1) + '/8.0)');
    }
}


/**
 * Autofills the credit count for minor.
**/
function fillMinCreditCount() {
    'use strict';

    if (minor.creditCount >= 4) {
        $('#min_creds').html('(4.0/4.0)');
    } else {
        $('#min_creds').html('(' + minor.creditCount.toFixed(1) + '/4.0)');
    }
}


/**
 * Autofills extra 200-level courses for last minor constraint.
**/
function addExtraMinCourses() {
    'use strict';

    var minExtra = $('#minextra')[0].getElementsByTagName('input');

    for (var m = 0; m < 3; m++) {
        if (minor.filledTextboxesExtra === minor.textboxesExtra) {
            break;      
        } else if (getCookie(minor.additionalMin200[m]) === 'active' || getCookie(minor.additionalMin200[m]) === 'overriden') {
            minExtra[minor.filledTextboxesExtra].value = minor.additionalMin200[m];
            minExtra[minor.filledTextboxesExtra].disabled = true;
            minor.creditCount += 0.5;
            minor.filledTextboxesExtra += 1;
        }
        
    }
}


/**
 * Checks whether a POSt is completed and updates credit count colour if it is.
**/
function checkPostCompleted() {
    'use strict';

    if (specialist.categoriesCompleted === specialist.categories) {
        $('#spec_creds').css('color', 'green');
    } else {
        $('#spec_creds').css('color', 'red');
    }
    
    if (major.categoriesCompleted === major.categories) {
        $('#maj_creds').css('color', 'green');
    } else {
        $('#maj_creds').css('color', 'red');
    } 

    if (minor.categoriesCompleted === minor.categories) {
        $('#min_creds').css('color', 'green');
    } else {
        $('#min_creds').css('color', 'red');
    }
}


/**
 * Updates the Nav Bar on the Check My Post! page
**/
function updateNavPost() {
    'use strict';

    var nav_post = $('#nav-links')[0].getElementsByTagName('li')[3].getElementsByTagName('a')[0];

    if (getCookie('specialist') === 'active') {
        nav_post.innerHTML = 'Check My POSt! (' + specialist.creditCount.toFixed(1) + '/12.0)';
        setCookie('activecount', specialist.creditCount.toFixed(1));
    } else if (getCookie('major') === 'active') {
        nav_post.innerHTML = 'Check My POSt! (' + major.creditCount.toFixed(1) + '/8.0)';
        setCookie('activecount', major.creditCount.toFixed(1));
    } else if (getCookie('minor') === 'active') {
        nav_post.innerHTML = 'Check My POSt! (' + minor.creditCount.toFixed(1) + '/4.0)';
        setCookie('activecount', minor.creditCount.toFixed(1));
    } 
}


/**
 * Updates the Nav Bar on the Graph page.
**/
function updateNavGraph() {
    'use strict';

    var nav_graph = $('#nav-links')[0].getElementsByTagName('li')[3].getElementsByTagName('a')[0];

    if (getCookie('specialist') === 'active') {
        nav_graph.innerHTML = 'Check My POSt! (' + getCookie('activecount') + '/12.0)';
    } else if (getCookie('major') === 'active') {
        nav_graph.innerHTML = 'Check My POSt! (' + getCookie('activecount') + '/8.0)';
    } else if (getCookie('minor') === 'active') {
        nav_graph.innerHTML = 'Check My POSt! (' + getCookie('activecount') + '/4.0)';
    } 
}


/**
 * Updates list of current active (selected) courses in Graph.
**/
function updateActiveCourses() {
    'use strict';

    activeCourses = [];

    // check for active CSC courses
    for (var areaName in areas) {
        if (areas.hasOwnProperty(areaName)) {
            for (var i = 0; i < areas[areaName].length; i++) {
                if ((getCookie(areas[areaName][i]) === 'active' || getCookie(areas[areaName][i]) === 'overridden') && 
                    areas[areaName][i] !== 'CSC104') {
                    activeCourses.push(areas[areaName][i]);
                }
            }
        }
    }

    // check for active math courses
    for (var i = 0; i < math.length; i++) {
        if (getCookie(math[i]) === 'active') {
            activeCourses.push(math[i]);
        }
    }
}

/**
 * Updates Credit count for MAT and STA courses.
**/
function updateMatCreditCount() {
    'use strict';

    var specExtra = $('#specextra')[0].getElementsByTagName('input');
    var majExtra = $('#majextra')[0].getElementsByTagName('input');

    for (var k = 0; k < 4; k++) {
        if (specExtra[k].value.indexOf('MAT') > -1 || specExtra[k].value.indexOf('STA') > -1) {
            specialist.creditCount += 0.5;
            specialist.filledTextboxesExtra += 1;
        } 
        if (k < 3 && (majExtra[k].value.indexOf('MAT') > -1 || majExtra[k].value.indexOf('STA') > -1)) {
                major.creditCount += 0.5;
                major.filledTextboxesExtra += 1;
        }
    }
}

