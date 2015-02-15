# Figure: Overlapping time series of global diagnostics on the MR network
library(bitriad)
source('code/mathrev2igraph.R')
source('code/triadic-spec.R')
load('calc/mathrev.RData')

# List of prefixes
char2s <- sort(unique(substr(mathrev$pclass, 1, 2)))
char2s <- char2s[grep('[0-9]{2}', char2s)]

# Degree sequences
char2s.degree <- lapply(years[-(1:2)], function(yr) {
    dat <- mathrev[mathrev$year %in% (yr - dur + 1):yr, ]
    lst <- lapply(char2s, function(s) {
        bigraph <- paper.author.graph(
            dat[substr(dat$pclass, 1, 2) == s, ]
        )
        if(vcount(bigraph) == 0) return(list(actor = c(), event = c()))
        deg <- degree(bigraph)
        list(
            actor = tabulate(deg[which(!V(bigraph)$type)]),
            event = tabulate(deg[which(V(bigraph)$type)])
        )
    })
})

# Compute triad censuses for each subdiscipline
# over three evenly-spaced intervals of equal duration
char2s.census <- lapply(years[-(1:2)], function(yr) {
    dat <- mathrev[mathrev$year %in% (yr - dur + 1):yr, ]
    lst <- lapply(char2s, function(s) {
        an.triad.census(paper.author.graph(
            dat[substr(dat$pclass, 1, 2) == s, ]))
    })
    names(lst) <- char2s
    return(lst)
})

# Compute global statistics for each subdiscipline
char2s.global <- lapply(char2s.census, function(lst) {
    do.call(rbind, lapply(lst, function(census) {
        c('C' = ftc2allact(census),
          'C.opsahl' = ftc2injequ(census),
          'C.excl' = ftc2indstr(census),
          'C.injstr' = ftc2injstr(census),
          'C.injact' = ftc2injact(census),
          'T' = ftc2allact(census, by.tri = TRUE),
          'T.excl' = ftc2indstr(census, by.tri = TRUE),
          'T.injact' = ftc2injact(census, by.tri = TRUE)
        )
    }))
})

# Compute wedge closure (both types) for each subdiscipline
char2s.closes <- lapply(years[-(1:2)], function(yr) {
    dat <- mathrev[mathrev$year %in% (yr - dur + 1):yr, ]
    do.call(rbind, lapply(char2s, function(s) {
        sdat <- dat[substr(dat$pclass, 1, 2) == s, ]
        return(c(DTC1 = wedge.closure(sdat, (yr - dur + 1), (yr - dur + 2):yr),
                 DTC2 = wedge.closure(sdat, (yr - dur + 1):(yr - dur + 2), yr)))
    }))
})

# Compute wedge closure (each type) for each subdiscipline
char2s.closed <- lapply(years[-(1:2)], function(yr) {
    dat <- mathrev[mathrev$year %in% (yr - dur + 1):yr, ]
    sapply(char2s, function(s) {
        sdat <- dat[substr(dat$pclass, 1, 2) == s, ]
        dyn.triadic.closure.bigraph(paper.author.graph(sdat),
                                    memory = Inf,
                                    type = 'global')
    })
})

# Save!
save(char2s.degree, char2s.census, char2s.global, char2s.closes, char2s.closed,
     file = 'calc/mathrev-char2s.RData')

rm(list = ls())