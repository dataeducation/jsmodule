#' @title FilePsInput: Shiny module UI for file upload for propensity score matching.
#' @description Shiny module UI for file upload for propensity score matching.
#' @param id id
#' @param label label, Default: 'csv/xlsx/sav/sas7bdat file'
#' @return Shiny module UI for file upload for propensity score matching.
#' @details Shiny module UI for file upload for propensity score matching.
#' @examples
#' library(shiny)
#' library(DT)
#' library(data.table)
#' library(readxl)
#' library(jstable)
#' ui <- fluidPage(
#'   sidebarLayout(
#'     sidebarPanel(
#'       FilePsInput("datafile")
#'     ),
#'     mainPanel(
#'       tabsetPanel(
#'         type = "pills",
#'         tabPanel("Data", DTOutput("data")),
#'         tabPanel("Matching data", DTOutput("matdata")),
#'         tabPanel("Label", DTOutput("data_label", width = "100%"))
#'       )
#'     )
#'   )
#' )
#'
#' server <- function(input, output, session) {
#'   mat.info <- callModule(FilePs, "datafile")
#'
#'   output$data <- renderDT({
#'     mat.info()$data
#'   })
#'
#'   output$matdata <- renderDT({
#'     mat.info()$matdata
#'   })
#'
#'   output$label <- renderDT({
#'     mat.info()$label
#'   })
#' }
#' @rdname FilePsInput
#' @export
#' @import shiny

FilePsInput <- function(id, label = "Upload data (csv/xlsx/sav/sas7bdat/dta)") {
  # Create a namespace function using the provided id
  ns <- NS(id)

  tagList(
    fileInput(ns("file"), label),
    uiOutput(ns("factor")),
    uiOutput(ns("binary_check")),
    uiOutput(ns("binary_var")),
    uiOutput(ns("binary_val")),
    uiOutput(ns("ref_check")),
    uiOutput(ns("ref_var")),
    uiOutput(ns("ref_val")),
    uiOutput(ns("subset_check")),
    uiOutput(ns("subset_var")),
    uiOutput(ns("subset_val")),
    uiOutput(ns("group_ps")),
    uiOutput(ns("indep_ps")),
    uiOutput(ns("pcut")),
    uiOutput(ns("caliperps")),
    uiOutput(ns("ratio"))
  )
}





#' @title FilePs: Shiny module Server for file upload for propensity score matching.
#' @description Shiny module Server for file upload for propensity score matching.
#' @param input input
#' @param output output
#' @param session session
#' @param nfactor.limit nfactor limit to include, Default: 20
#' @return Shiny module Server for file upload for propensity score matching.
#' @details Shiny module Server for file upload for propensity score matching.
#' @examples
#' library(shiny)
#' library(DT)
#' library(data.table)
#' library(readxl)
#' library(jstable)
#' ui <- fluidPage(
#'   sidebarLayout(
#'     sidebarPanel(
#'       FilePsInput("datafile")
#'     ),
#'     mainPanel(
#'       tabsetPanel(
#'         type = "pills",
#'         tabPanel("Data", DTOutput("data")),
#'         tabPanel("Matching data", DTOutput("matdata")),
#'         tabPanel("Label", DTOutput("data_label", width = "100%"))
#'       )
#'     )
#'   )
#' )
#'
#' server <- function(input, output, session) {
#'   mat.info <- callModule(FilePs, "datafile")
#'
#'   output$data <- renderDT({
#'     mat.info()$data
#'   })
#'
#'   output$matdata <- renderDT({
#'     mat.info()$matdata
#'   })
#'
#'   output$label <- renderDT({
#'     mat.info()$label
#'   })
#' }
#' @rdname FilePs
#' @export
#' @import shiny
#' @importFrom data.table fread data.table .SD :=
#' @importFrom readxl read_excel
#' @importFrom readr guess_encoding
#' @importFrom utils read.csv
#' @importFrom jstable mk.lev
#' @importFrom haven read_sav read_sas
#' @importFrom MatchIt matchit match.data

FilePs <- function(input, output, session, nfactor.limit = 20) {
  ## To remove NOTE.
  ID.pscal2828 <- BinaryGroupRandom <- variable <- val_label <- NULL

  # The selected file, if any
  userFile <- eventReactive(input$file, {
    # If no file is selected, don't do anything
    # validate(need(input$file, message = FALSE))
    input$file
  })

  mklist <- function(varlist, vars) {
    lapply(
      varlist,
      function(x) {
        inter <- intersect(x, vars)
        if (length(inter) == 1) {
          inter <- c(inter, "")
        }
        return(inter)
      }
    )
  }





  data.info <- eventReactive(input$file, {
    validate(need((grepl("csv", userFile()$name) == T) | (grepl("xlsx", userFile()$name) == T) | (grepl("sav", userFile()$name) == T) | (grepl("sas7bdat", userFile()$name) == T), message = "Please upload csv/xlsx/sav/sas7bdat file"))
    if (grepl("csv", userFile()$name) == T) {
      out <- data.table::fread(userFile()$datapath, check.names = F, integer64 = "double")
      if (readr::guess_encoding(userFile()$datapath)[1, 1] == "EUC-KR") {
        out <- data.table::data.table(utils::read.csv(userFile()$datapath, check.names = F, fileEncoding = "EUC-KR"))
      }
    } else if (grepl("xlsx", userFile()$name) == T) {
      out <- data.table::data.table(readxl::read_excel(userFile()$datapath), check.names = F, integer64 = "double")
    } else if (grepl("sav", userFile()$name) == T) {
      out <- data.table::data.table(tryCatch(haven::read_sav(userFile()$datapath), error = function(e) {
        return(haven::read_sav(userFile()$datapath, encoding = "latin1"))
      }), check.names = F)
      # out = data.table::data.table(haven::read_sav(userFile()$datapath, encoding = "latin1"), check.names = F, integer64 = "double")
    } else if (grepl("sas7bdat", userFile()$name) == T) {
      out <- data.table::data.table(tryCatch(haven::read_sas(userFile()$datapath), error = function(e) {
        return(haven::read_sas(userFile()$datapath, encoding = "latin1"))
      }), check.names = F)
      # out = data.table::data.table(haven::read_sas(userFile()$datapath), check.names = F, integer64 = "double")
    } else if (grepl("dta", userFile()$name) == T) {
      out <- data.table::data.table(tryCatch(haven::read_dta(userFile()$datapath), error = function(e) {
        return(haven::read_dta(userFile()$datapath, encoding = "latin1"))
      }), check.names = F)
      # out = data.table::data.table(haven::read_dta(userFile()$datapath), check.names = F, integer64 = "double")
    } else {
      stop("Not supported format.")
    }


    out.old <- out
    name.old <- names(out.old)
    out <- data.table::data.table(out, check.names = T)
    name.new <- names(out)
    ref <- list(name.old = name.old, name.new = name.new)



    naCol <- names(out)[colSums(is.na(out)) > 0]
    # out <- out[, .SD, .SDcols = -naCol]

    data_varStruct <- list(variable = names(out))

    factor_vars <- names(out)[out[, lapply(.SD, class) %in% c("factor", "character")]]
    if (!is.null(factor_vars) & length(factor_vars) > 0) {
      out[, (factor_vars) := lapply(.SD, as.factor), .SDcols = factor_vars]
    }

    conti_vars <- setdiff(names(out), factor_vars)
    nclass <- unlist(out[, lapply(.SD, function(x) {
      length(unique(x))
    }), .SDcols = conti_vars])
    factor_adds_list <- mklist(data_varStruct, names(nclass)[(nclass <= nfactor.limit) & (nclass < nrow(out))])

    # except_vars <- names(nclass)[ nclass== 1 | nclass >= nfactor.limit]
    except_vars <- names(nclass)[nclass == 1]
    add_vars <- names(nclass)[nclass >= 1 & nclass <= 5]
    # factor_vars_ini <- union(factor_vars, add_vars)
    naomit <- ifelse(length(naCol) == 0, "Data has <B>no</B> missing values.", paste("Column <B>", paste(naCol, collapse = ", "), "</B> contain missing values.", sep = ""))
    return(list(
      data = out, data_varStruct = data_varStruct, factor_original = factor_vars,
      conti_original = conti_vars, factor_adds_list = factor_adds_list,
      factor_adds = add_vars, naCol = naCol, except_vars = except_vars, ref = ref, naomit = naomit
    ))
  })

  # naomit <- eventReactive(data.info(), {
  #  req(data.info())
  #  if (length(data.info()$naCol) == 0) {
  #    return("Data has <B>no</B> missing values.")
  #  } else{
  #    txt_miss <- paste(data.info()$naCol, collapse = ", ")
  #    return(paste("Column <B>", txt_miss, "</B> are(is) excluded due to missing value.", sep = ""))
  #  }
  # })

  output$pcut <- renderUI({
    if (is.null(input$file)) {
      return(NULL)
    }

    radioButtons(session$ns("pcut_ps"),
      label = "Default p-value cut for ps calculation",
      choices = c("No", 0.05, 0.1, 0.2),
      selected = "No", inline = T
    )
  })

  output$ratio <- renderUI({
    if (is.null(input$file)) {
      return(NULL)
    }
    radioButtons(session$ns("ratio_ps"),
      label = "Case:control ratio",
      choices = c("1:1" = 1, "1:2" = 2, "1:3" = 3, "1:4" = 4),
      selected = 1, inline = T
    )
  })


  observeEvent(data.info(), {
    output$factor <- renderUI({
      selectInput(session$ns("factor_vname"),
        label = "Additional categorical variables",
        choices = data.info()$factor_adds_list, multiple = T,
        selected = data.info()$factor_adds
      )
    })
  })


  observeEvent(c(data.info()$factor_original, input$factor_vname), {
    output$binary_check <- renderUI({
      checkboxInput(session$ns("check_binary"), "Make binary variables")
    })

    output$ref_check <- renderUI({
      checkboxInput(session$ns("check_ref"), "Change reference of categorical variables")
    })

    output$subset_check <- renderUI({
      checkboxInput(session$ns("check_subset"), "Subset data")
    })
  })

  observeEvent(input$check_binary, {
    var.conti <- setdiff(names(data.info()$data), c(data.info()$factor_original, input$factor_vname))
    output$binary_var <- renderUI({
      req(input$check_binary == T)
      selectInput(session$ns("var_binary"), "Variables to dichotomize",
        choices = var.conti, multiple = T,
        selected = var.conti[1]
      )
    })

    output$binary_val <- renderUI({
      req(input$check_binary == T)
      req(length(input$var_binary) > 0)
      outUI <- tagList()
      for (v in seq_along(input$var_binary)) {
        med <- stats::quantile(data.info()$data[[input$var_binary[[v]]]], c(0.05, 0.5, 0.95), na.rm = T)
        outUI[[v]] <- splitLayout(
          cellWidths = c("25%", "75%"),
          selectInput(session$ns(paste0("con_binary", v)), paste0("Define reference:"),
            choices = c("\u2264", "\u2265", "\u003c", "\u003e"), selected = "\u2264"
          ),
          numericInput(session$ns(paste0("cut_binary", v)), input$var_binary[[v]],
            value = med[2], min = med[1], max = med[3]
          )
        )
      }
      outUI
    })
  })

  observeEvent(input$check_ref, {
    var.factor <- c(data.info()$factor_original, input$factor_vname)
    output$ref_var <- renderUI({
      req(input$check_ref == T)
      selectInput(session$ns("var_ref"), "Variables to change reference",
        choices = var.factor, multiple = T,
        selected = var.factor[1]
      )
    })

    output$ref_val <- renderUI({
      req(input$check_ref == T)
      req(length(input$var_ref) > 0)
      outUI <- tagList()
      for (v in seq_along(input$var_ref)) {
        outUI[[v]] <- selectInput(session$ns(paste0("con_ref", v)), paste0("Reference: ", input$var_ref[[v]]),
          choices = levels(factor(data.info()$data[[input$var_ref[[v]]]])), selected = levels(factor(data.info()$data[[input$var_ref[[v]]]]))[2]
        )
      }
      outUI
    })
  })


  observeEvent(input$check_subset, {
    output$subset_var <- renderUI({
      req(input$check_subset == T)
      # factor_subset <- c(data.info()$factor_original, input$factor_vname)

      # validate(
      #  need(length(factor_subset) > 0 , "No factor variable for subsetting")
      # )

      tagList(
        selectInput(session$ns("var_subset"), "Subset variables",
          choices = names(data.info()$data), multiple = T,
          selected = names(data.info()$data)[1]
        )
      )
    })

    output$subset_val <- renderUI({
      req(input$check_subset == T)
      req(length(input$var_subset) > 0)
      var.factor <- c(data.info()$factor_original, input$factor_vname)

      outUI <- tagList()

      for (v in seq_along(input$var_subset)) {
        if (input$var_subset[[v]] %in% var.factor) {
          varlevel <- levels(as.factor(data.info()$data[[input$var_subset[[v]]]]))
          outUI[[v]] <- selectInput(session$ns(paste0("val_subset", v)), paste0("Subset value: ", input$var_subset[[v]]),
            choices = varlevel, multiple = T,
            selected = varlevel[1]
          )
        } else {
          val <- stats::quantile(data.info()$data[[input$var_subset[[v]]]], na.rm = T)
          outUI[[v]] <- sliderInput(session$ns(paste0("val_subset", v)), paste0("Subset range: ", input$var_subset[[v]]),
            min = val[1], max = val[5],
            value = c(val[2], val[4])
          )
        }
      }
      outUI
    })
  })



  # We can run observers in here if we want to
  observe({
    msg <- sprintf("File %s was uploaded", userFile()$name)
    cat(msg, "\n")
  })



  data <- reactive({
    req(input$factor_vname)
    out <- data.table::data.table(data.info()$data)
    out[, (data.info()$conti_original) := lapply(.SD, function(x) {
      as.numeric(as.vector(x))
    }), .SDcols = data.info()$conti_original]
    if (length(input$factor_vname) > 0) {
      out[, (input$factor_vname) := lapply(.SD, as.factor), .SDcols = input$factor_vname]
    }

    ref <- data.info()$ref
    out.label <- mk.lev(out)

    if (tools::file_ext(input$file$name) == "sav") {
      out.label <- mk.lev2(data()$data.old, out.label)
    }

    if (!is.null(input$check_binary)) {
      if (input$check_binary) {
        validate(
          need(length(input$var_binary) > 0, "No variables to dichotomize")
        )
        sym.ineq <- c("\u2264", "\u2265", "\u003c", "\u003e")
        names(sym.ineq) <- sym.ineq[4:1]
        sym.ineq2 <- c("le", "ge", "l", "g")
        names(sym.ineq2) <- sym.ineq
        for (v in seq_along(input$var_binary)) {
          req(input[[paste0("con_binary", v)]])
          req(input[[paste0("cut_binary", v)]])
          if (input[[paste0("con_binary", v)]] == "\u2264") {
            out[, BinaryGroupRandom := factor(1 - as.integer(get(input$var_binary[[v]]) <= input[[paste0("cut_binary", v)]]))]
          } else if (input[[paste0("con_binary", v)]] == "\u2265") {
            out[, BinaryGroupRandom := factor(1 - as.integer(get(input$var_binary[[v]]) >= input[[paste0("cut_binary", v)]]))]
          } else if (input[[paste0("con_binary", v)]] == "\u003c") {
            out[, BinaryGroupRandom := factor(1 - as.integer(get(input$var_binary[[v]]) < input[[paste0("cut_binary", v)]]))]
          } else {
            out[, BinaryGroupRandom := factor(1 - as.integer(get(input$var_binary[[v]]) > input[[paste0("cut_binary", v)]]))]
          }

          cn.new <- paste0(input$var_binary[[v]], "_group_", sym.ineq2[input[[paste0("con_binary", v)]]], input[[paste0("cut_binary", v)]])
          data.table::setnames(out, "BinaryGroupRandom", cn.new)

          label.binary <- mk.lev(out[, .SD, .SDcols = cn.new])
          label.binary[, var_label := paste0(input$var_binary[[v]], " _group")]
          label.binary[, val_label := paste0(c(input[[paste0("con_binary", v)]], sym.ineq[input[[paste0("con_binary", v)]]]), " ", input[[paste0("cut_binary", v)]])]
          out.label <- rbind(out.label, label.binary)
        }
      }
    }


    if (!is.null(input$check_ref)) {
      if (input$check_ref) {
        validate(
          need(length(input$var_ref) > 0, "No variables to change reference")
        )
        for (v in seq_along(input$var_ref)) {
          req(input[[paste0("con_ref", v)]])
          out[[input$var_ref[[v]]]] <- stats::relevel(out[[input$var_ref[[v]]]], ref = input[[paste0("con_ref", v)]])
          out.label[variable == input$var_ref[[v]], ":="(level = levels(out[[input$var_ref[[v]]]]), val_label = levels(out[[input$var_ref[[v]]]]))]
        }
      }
    }

    if (!is.null(input$check_subset)) {
      if (input$check_subset) {
        validate(
          need(length(input$var_subset) > 0, "No variables for subsetting"),
          need(all(sapply(1:length(input$var_subset), function(x) {
            length(input[[paste0("val_subset", x)]])
          })), "No value for subsetting")
        )

        var.factor <- c(data.info()$factor_original, input$factor_vname)
        # var.conti <- setdiff(data()$conti_original, input$factor_vname)

        for (v in seq_along(input$var_subset)) {
          if (input$var_subset[[v]] %in% var.factor) {
            out <- out[get(input$var_subset[[v]]) %in% input[[paste0("val_subset", v)]]]
            # var.factor <- c(data()$factor_original, input$factor_vname)
            out[, (var.factor) := lapply(.SD, factor), .SDcols = var.factor]
            out.label2 <- mk.lev(out)[, c("variable", "level")]
            data.table::setkey(out.label, "variable", "level")
            data.table::setkey(out.label2, "variable", "level")
            out.label <- out.label[out.label2]
          } else {
            out <- out[get(input$var_subset[[v]]) >= input[[paste0("val_subset", v)]][1] & get(input$var_subset[[v]]) <= input[[paste0("val_subset", v)]][2]]
            # var.factor <- c(data()$factor_original, input$factor_vname)
            out[, (var.factor) := lapply(.SD, factor), .SDcols = var.factor]
            out.label2 <- mk.lev(out)[, c("variable", "level")]
            data.table::setkey(out.label, "variable", "level")
            data.table::setkey(out.label2, "variable", "level")
            out.label <- out.label[out.label2]
          }
        }
      }
    }

    for (vn in ref[["name.new"]]) {
      w <- which(ref[["name.new"]] == vn)
      out.label[variable == vn, var_label := ref[["name.old"]][w]]
    }
    out.label <- rbind(out.label, data.table(variable = "pscore", class = "numeric", level = NA, var_label = "pscore", val_label = NA))

    return(list(data = out, label = out.label, data_varStruct = list(variable = names(out)), except_vars = data.info()$except_vars))
  })



  observeEvent(data(), {
    output$group_ps <- renderUI({
      # req(data())
      factor_vars <- names(data()$data)[data()$data[, lapply(.SD, class) %in% c("factor", "character")]]
      validate(
        need(!is.null(factor_vars) & length(factor_vars) > 0, "No categorical variables in data")
      )

      class01_factor <- unlist(data()$data[, lapply(.SD, function(x) {
        identical(levels(x), c("0", "1"))
      }), .SDcols = factor_vars])
      # nclass_factor <- unlist(data()[, lapply(.SD, function(x){length(unique(x))}), .SDcols = factor_vars])
      # factor_2vars <- names(nclass_factor)[nclass_factor == 2]


      validate(
        need(!is.null(class01_factor), "No categorical variables coded as 0, 1 in data")
      )

      factor_01vars <- factor_vars[class01_factor]
      factor_01vars_case_small <- factor_01vars[unlist(sapply(factor_01vars, function(x) {
        diff(table(data()$data[[x]])) <= 0
      }))]

      validate(
        need(length(factor_01vars_case_small) > 0, "No candidate group variable for PS calculation")
      )

      selectInput(session$ns("group_pscal"),
        label = "Group variable for PS calculation (0, 1 coding)",
        choices = mklist(data()$data_varStruct, factor_01vars_case_small), multiple = F,
        selected = factor_01vars_case_small[1]
      )
    })

    output$indep_ps <- renderUI({
      req(!is.null(input$group_pscal))
      validate(
        need(length(input$group_pscal) != 0, "No group variables in data")
      )

      vars <- setdiff(setdiff(names(data()$data), data()$except_vars), c(input$var_subset, input$group_pscal))
      varsIni <- 1
      if (input$pcut_ps != "No") {
        varsIni <- sapply(
          vars,
          function(v) {
            forms <- as.formula(paste(input$group_pscal, "~", v))
            coef <- tryCatch(summary(glm(forms, data = data()$data, family = binomial))$coefficients, error = function(e) {
              return(NULL)
            })
            sigOK <- !all(coef[-1, 4] > as.numeric(input$pcut_ps))
            return(sigOK)
          }
        )
      }

      tagList(
        selectInput(session$ns("indep_pscal"),
          label = "Independent variables for PS calculation",
          choices = mklist(data()$data_varStruct, vars), multiple = T,
          selected = vars[varsIni]
        )
      )
    })

    output$caliperps <- renderUI({
      sliderInput(session$ns("caliper"), "Caliper (0: no)", value = 0, min = 0, max = 1)
    })
  })






  mat.info <- eventReactive(c(input$indep_pscal, input$group_pscal, input$caliper, input$ratio_ps, data()), {
    req(input$indep_pscal)
    if (is.null(input$group_pscal) | is.null(input$indep_pscal)) {
      return(NULL)
    }
    data <- data.table(data()$data)
    data$ID.pscal2828 <- 1:nrow(data)
    case.naomit <- which(complete.cases(data[, .SD, .SDcols = c(input$group_pscal, input$indep_pscal)]))
    data.naomit <- data[case.naomit]
    data.na <- data[-case.naomit]
    data.na$pscore <- NA
    data.na$iptw <- NA
    caliper <- NULL
    if (input$caliper > 0) {
      caliper <- input$caliper
    }

    forms <- as.formula(paste(input$group_pscal, " ~ ", paste(input$indep_pscal, collapse = "+"), sep = ""))
    m.out <- MatchIt::matchit(forms, data = data.naomit[, .SD, .SDcols = c("ID.pscal2828", input$group_pscal, input$indep_pscal)], caliper = caliper, ratio = as.integer(input$ratio_ps))
    pscore <- m.out$distance
    iptw <- ifelse(m.out$treat == levels(factor(m.out$treat))[2], 1 / pscore, 1 / (1 - pscore))

    wdata <- rbind(data.na, cbind(data.naomit, pscore, iptw))

    return(list(data = wdata, matdata = data[ID.pscal2828 %in% match.data(m.out)$ID.pscal2828], data.label = data()$label, naomit = data.info()$naomit, group_var = input$group_pscal))
  })






  # Return the reactive that yields the data frame
  return(mat.info)
}
